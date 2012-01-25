###
Backbone Query - A lightweight query API for Backbone Collections
(c)2012 - Dave Tonge
May be freely distributed according to MIT license.
###

# Array Intersection - Helper Function
# * Modified version of Underscore Intersection, accepts an array of arrays rather than multiple arrays
# * Returns results that are present in each of the supplied arrays
array_intersection = (arrays) ->
  rest = _.rest arrays
  _.filter _.uniq(arrays[0]), (item) ->
    _.every rest, (other) ->
      _.indexOf(other, item) >= 0


# This function parses the query and converts it into an array of objects.
# Each object has a key (model property), type (query type - $gt, $like...) and value (mixed).
parse_query = (raw_query) ->
  (for key, query_param of raw_query
    o = {key}

    # Test for Regexs as they can be supplied without an operator
    if _.isRegExp(query_param)
      o.type = "$regex"
      o.value = query_param
    # If the query paramater is an object then extract the key and value
    else if _(query_param).isObject()
      for type, value of query_param
        # Before adding the query, its value is checked to make sure it is the right type
        if test_query_value type, value
          o.type = type
          o.value = value
    # If the query_param is not an object or a regexp then revert to the default operator: $equal
    else
      o.type = "$equal"
      o.value = query_param
    o)

# Tests query value, to ensure that it is of the correct type
test_query_value = (type, value) ->
  switch type
    when "$in","$nin","$all", "$any" then _(value).isArray()
    when "$size" then _(value).isNumber()
    when "$regex" then _(value).isRegExp()
    when "$like" then _(value).isString()
    when "$between" then _(value).isArray() and (value.length is 2)
    when "$cb" then _(value).isFunction()
    else true

# The main iterator that actually applies the query
iterator = (collection, query, andOr) ->
  parsed_query = parse_query query
  # The collections filter method is used to iterate through each model in the collection
  collection.filter (model) ->
    # For each model in the collection, iterate through the supplied queries
    for q in parsed_query
      attr = model.get(q.key)
      # If the query is an "or" query than as soon as a match is found we return "true"
      # Whereas if the query is an "and" query then we return "false" as soon as a match isn't found.
      return andOr if andOr is (switch q.type
        when "$equal" then attr is q.value
        when "$contains"
          #For this method the model attribute is confirmed to be an array before looping through it
          if _(attr).isArray() then (q.value in attr) else false
        when "$ne" then attr isnt q.value
        when "$lt" then attr < q.value
        when "$gt" then attr > q.value
        when "$lte" then attr <= q.value
        when "$gte" then attr >= q.value
        when "$between" then q.value[0] < attr < q.value[1]
        when "$in" then  attr in q.value
        when "$nin" then  attr not in q.value
        when "$all"
          #For this method the model attribute is confirmed to be an array before looping through it
          if _(attr).isArray()
            _(model.get q.key).all (item) -> item in q.value
        when "$any"
          #For this method the model attribute is confirmed to be an array before looping through it
          if _(attr).isArray()
            _(model.get q.key).any (item) -> item in q.value
        when "$size" then attr.length is q.value
        when "$exists", "$has" then model.has(q.key) is q.value
        when "$like" then attr.indexOf(q.value) isnt -1
        when "$regex" then q.value.test attr
        when "$cb" then q.value.call model, attr)
    # For an "or" query, if all the queries are false, then we return false
    # For an "and" query, if all the queries are true, then we return true
    not andOr

and_iterator = (collection, query) -> iterator collection, query, false
or_iterator = (collection, query) -> iterator collection, query, true

# A object with or, and, nor and not methods
process_query =
  $and: (collection, query) -> and_iterator collection, query
  $or: (collection, query) -> or_iterator collection, query
  $nor: (collection, query) -> _.difference collection.models, (or_iterator collection, query)
  $not: (collection, query) -> _.difference collection.models, (and_iterator collection, query)

get_cache = (collection, query, options) ->
  # Convert the query to a string to use as a key in the cache
  query_string = JSON.stringify query
  # Create cache if doesn't exist
  cache = collection._query_cache ?= {}
  # Retrieve cached results
  models = cache[query_string]
  # If no results are retrieved then use the get_models method and cache the result
  unless models
    models = get_sorted_models collection, query, options
    cache[query_string] = models
  # Return the results
  models

get_models = (collection, query) ->

  # Iterate through the query keys to check for any of the compound methods
  compound_query = _(query).chain().keys().intersection(["$or", "$and", "$nor", "$not"]).value()

  (switch compound_query.length
    # If no compound methods are found then use the "and" iterator
    when 0 then process_query.$and collection, query

    # If only 1 compound method then invoke just that method
    when 1
      type = compound_query[0]
      process_query[type] collection, query[type]

    # If more than 1 method is found, process each of the methods
    else
      results = (for type in compound_query
        process_query[type] collection, query[type])

      # A modified form of Underscores Intersection is used to find the models that appear in all the result sets
      array_intersection results)

# Gets the results and optionally sorts them
get_sorted_models = (collection, query, options) ->
  models = get_models collection, query
  if options.sortBy then models = sort_models models, options
  models

# Sorts models either be a model attribute or with a callback
sort_models = (models, options) ->
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
page_models = (models, options) ->
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




Backbone.QueryCollection = Backbone.Collection.extend

  # The main query method
  query: (query, options = {}) ->

    # Retrieve matching models using the supplied query
    if options.cache
      models = get_cache @, query, options
    else
      models = get_sorted_models @, query, options

    # If a limit param is specified than slice the results
    if options.limit then models = page_models models, options

    # Return the results
    models

  # Helper method to reset the query cache
  # Defined as a separate method to make it easy to bind to collection's change/add/remove events
  reset_query_cache: -> @_query_cache = {}