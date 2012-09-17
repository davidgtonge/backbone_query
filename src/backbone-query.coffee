###
Backbone Query - A lightweight query API for Backbone Collections
(c)2012 - Dave Tonge
May be freely distributed according to MIT license.
###


### UTILS ###

# Custom Filter / Reject methods faster than underscore methods as use for loops
# http://jsperf.com/filter-vs-for-loop2
filter = (array, test) -> (val for val in array when test val)
reject = (array, test) -> (val for val in array when not test val)
detect = (array, test) ->
  for val in array
    return true if test val
  false

# Utility Function to turn a list of values into an object
makeObj = (args...)->
  o = {}
  current = o
  while args.length
    key = args.shift()
    val = (if args.length is 1 then args.shift() else {})
    current = current[key] = val
  o

# Get the type as a string
getType = (item) ->
  return "$regex" if _.isRegExp(item)
  return "$date" if _.isDate(item)
  return "object" if _.isObject(item) and not _.isArray(item)
  return "array" if _.isArray(item)
  return "string" if _.isString(item)
  return "number" if _.isNumber(item)
  return "boolean" if _.isBoolean(item)
  return "function" if _.isFunction(item)
  false

###
Function to parse raw queries
@param {mixed} raw query
@return {array} parsed query

Allows queries of the following forms:
query
  name: "test"
  id: $gte: 10

query [
  {name:"test"}
  {id:$gte:10}
]
###
parseQuery = (rawQuery) ->

  if _.isArray(rawQuery)
    queryArray = rawQuery
  else
    queryArray = (makeObj(key, val) for own key, val of rawQuery)

  (for query in queryArray
    for own key, queryParam of query
      o = {key}
      paramType = getType(queryParam)
      switch paramType
        # Test for Regexs and Dates as they can be supplied without an operator
        when "$regex", "$date"
          o.type = paramType
          o.value = queryParam

        # If the query paramater is an object then extract the key and value
        when "object"
          if key in ["$and", "$or", "$nor", "$not"]
            o.value = parseQuery(queryParam)
            o.type = key
            o.key = null
          else
            for type, value of queryParam
              # Before adding the query, its value is checked to make sure it is the right type
              if testQueryValue type, value
                o.type = type
                switch type
                  when "$elemMatch", "$relationMatch"
                    o.value = parseQuery value
                  when "$computed"
                    q = makeObj(key,value)
                    o.value = parseQuery q
                  else
                    o.value = value

        # If the query_param is not an object or a regexp then revert to the default operator: $equal
        else
          o.type = "$equal"
          o.value = queryParam

      # For "$equal" queries with arrays or objects we need to perform a deep equal
      if (o.type is "$equal") and (paramType in ["object","array"])
        o.type = "$oEqual"
    o)



# Tests query value, to ensure that it is of the correct type
testQueryValue = (type, value) ->
  switch type
    when "$in","$nin","$all", "$any"  then _(value).isArray()
    when "$size"                      then _(value).isNumber()
    when "$regex"                     then _(value).isRegExp()
    when "$like", "$likeI"            then _(value).isString()
    when "$between"                   then _(value).isArray() and (value.length is 2)
    when "$cb"                        then _(value).isFunction()
    else true

# Test each attribute that is being tested to ensure that is of the correct type
testModelAttribute = (type, value) ->
  switch type
    when "$like", "$likeI", "$regex"  then _(value).isString()
    when "$contains", "$all", "$any", "$elemMatch" then _(value).isArray()
    when "$size"                      then _(value).isArray() or _(value).isString()
    when "$in", "$nin"                then value?
    when "$relationMatch"             then value? and value.models
    else true

# Perform the actual query logic for each query and each model/attribute
performQuery = (type, value, attr, model, key) ->
  switch type
    when "$equal"
      # If the attrubute is an array then search for the query value in the array the same as Mongo
      if _(attr).isArray()  then value in attr else attr is value
    when "$oEqual"          then _(attr).isEqual value
    when "$contains"        then value in attr
    when "$ne"              then attr isnt value
    when "$lt"              then attr < value
    when "$gt"              then attr > value
    when "$lte"             then attr <= value
    when "$gte"             then attr >= value
    when "$between"         then value[0] < attr < value[1]
    when "$in"              then attr in value
    when "$nin"             then attr not in value
    when "$all"             then _(value).all (item) -> item in attr
    when "$any"             then _(attr).any (item) -> item in value
    when "$size"            then attr.length is value
    when "$exists", "$has"  then attr? is value
    when "$like"            then attr.indexOf(value) isnt -1
    when "$likeI"           then attr.toLowerCase().indexOf(value.toLowerCase()) isnt -1
    when "$regex"           then value.test attr
    when "$cb"              then value.call model, attr
    when "$elemMatch"       then iterator attr, value, false, detect, "elemMatch"
    when "$relationMatch"   then iterator attr.models, value, false, detect, "relationMatch"
    when "$computed"        then iterator [model], value, false, detect, "computed"
    when "$and", "$or", "$nor", "$not"
      (processQuery[type]([model], value)).length
    else false


# The main iterator that actually applies the query
iterator = (models, query, andOr, filterFunction, subQuery = false) ->
  parsedQuery = if subQuery then query else parseQuery query
  # The collections filter or reject method is used to iterate through each model in the collection
  filterFunction models, (model) ->
    # For each model in the collection, iterate through the supplied queries
    for q in parsedQuery
      # Retrieve the attribute value from the model
      attr = switch subQuery
        when "elemMatch" then model[q.key]
        when "computed" then model[q.key]()
        else model.get(q.key)
      # Check if the attribute value is the right type (some operators need a string, or an array)
      test = testModelAttribute(q.type, attr)
      # If the attribute test is true, perform the query
      if test then test = performQuery q.type, q.value, attr, model, q.key
      # If the query is an "or" query than as soon as a match is found we return "true"
      # Whereas if the query is an "and" query then we return "false" as soon as a match isn't found.
      return andOr if andOr is test

    # For an "or" query, if all the queries are false, then we return false
    # For an "and" query, if all the queries are true, then we return true
    not andOr



# An object with or, and, nor and not methods
processQuery =
  $and: (models, query) -> iterator models, query, false, filter
  $or: (models, query) -> iterator models, query, true, filter
  $nor: (models, query) -> iterator models, query, true, reject
  $not: (models, query) -> iterator models, query, false, reject


# This method attempts to retrieve the result from the cache.
# If no match is found in the cache, then the query is run and
# the results are saved in the cache
getCache = (collection, query, options) ->
  # Convert the query to a string to use as a key in the cache
  queryString = JSON.stringify query
  # Create cache if doesn't exist
  cache = collection._queryCache ?= {}
  # Retrieve cached results
  models = cache[queryString]
  # If no results are retrieved then use the get_models method and cache the result
  unless models
    models = getSortedModels collection, query, options
    cache[queryString] = models
  # Return the results
  models

# This method get the unsorted results
getModels = (collection, query) ->

  # Iterate through the query keys to check for any of the compound methods
  # The resulting array will have "$and" and "$not" first as it is better to use these
  # operators first when performing a compound query as they are likely to return less results
  queryKeys =  _(query).keys()
  compoundKeys = ["$and", "$not", "$or", "$nor"]
  compoundQuery = _.intersection compoundKeys, queryKeys

  if compoundQuery.length is 0
    # If no compound methods are found then use the "and" iterator
    processQuery.$and collection.models, query
  else
    # Detect if there is an implicit $and compundQuery operator
    if compoundQuery.length isnt queryKeys.length
      # Add the and compund query operator (with a sanity check that it doesn't exist)
      if "$and" not in compoundQuery
        query.$and = {}
        compoundQuery.unshift "$and"
      for own key, val of query when key not in compoundKeys
        query.$and[key] = val
        delete query[key]


    # Iterate through the compound methods using underscore reduce
    # The reduce iterator takes an array of models, performs the query and returns
    # the matched models for the next query
    reduceIterator = (memo, queryType) ->
      processQuery[queryType] memo, query[queryType]

    _.reduce compoundQuery, reduceIterator, collection.models

# Gets the results and optionally sorts them
getSortedModels = (collection, query, options) ->
  models = getModels collection, query
  if options.sortBy then models = sortModels models, options
  models

# Sorts models either be a model attribute or with a callback
sortModels = (models, options) ->
  # If the sortBy param is a string then we sort according to the model attribute with that string as a key
  if _(options.sortBy).isString()
    models = _(models).sortBy (model) -> model.get(options.sortBy)
  # If a function is supplied then it is passed directly to the sortBy iterator
  else if _(options.sortBy).isFunction()
    models = _(models).sortBy(options.sortBy)

  # If there is an order property of "desc" then the results can be reversed
  # (sortBy provides result in ascending order by default)
  if options.order is "desc" then models = models.reverse()
  # The sorted models are returned
  models

# Slices the results set according to the supplied options
pageModels = (models, options) ->
  # Expects object in the form: {limit: num, offset: num,  page: num, pager:callback}
  if options.offset then start = options.offset
  else if options.page then start = (options.page - 1) * options.limit
  else start = 0

  end = start + options.limit

  # The results are sliced according to the calculated start and end params
  sliced_models = models[start...end]

  if options.pager and _.isFunction(options.pager)
    total_pages = Math.ceil (models.length / options.limit)
    options.pager total_pages, sliced_models

  sliced_models

# If used on the server, then Backbone and Underscore are loaded as modules
unless typeof require is 'undefined'
  _ = require 'underscore'
  Backbone = require 'backbone'

Backbone.QueryCollection = Backbone.Collection.extend

  # The main query method
  query: (query, options = {}) ->

    # Retrieve matching models using the supplied query
    if options.cache
      models = getCache @, query, options
    else
      models = getSortedModels @, query, options

    # If a limit param is specified than slice the results
    if options.limit then models = pageModels models, options

    # Return the results
    models

  findOne: (query) -> @query(query)[0]

  # Where method wraps query and returns a new collection
  whereBy: (params, options = {})->
    new @constructor @query params, options

  # Helper method to reset the query cache
  # Defined as a separate method to make it easy to bind to collection's change/add/remove events
  resetQueryCache: -> @_queryCache = {}

# On the server the new Query Collection is added to exports
unless typeof exports is "undefined"
  exports.QueryCollection = Backbone.QueryCollection
