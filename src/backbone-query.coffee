###
Backbone Query - A lightweight query API for Backbone Collections
(c)2012 - Dave Tonge
May be freely distributed according to MIT license.
###

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
    when "$in","$nin","$all", "$any"  then _(value).isArray()
    when "$size"                      then _(value).isNumber()
    when "$regex"                     then _(value).isRegExp()
    when "$like", "$likeI"            then _(value).isString()
    when "$between"                   then _(value).isArray() and (value.length is 2)
    when "$cb"                        then _(value).isFunction()
    else true

# Test each attribute that is being tested to ensure that is of the correct type
test_model_attribute = (type, value) ->
  switch type
    when "$like", "$likeI", "$regex"  then _(value).isString()
    when "$contains", "$all", "$any"  then _(value).isArray()
    when "$size"                      then _(value).isArray() or _(value).isString()
    when "$in", "$nin"                then value?
    else true

# Perform the actual query logic for each query and each model/attribute
perform_query = (type, value, attr, model) ->
  switch type
    when "$equal"           then attr is value
    when "$contains"        then value in attr
    when "$ne"              then attr isnt value
    when "$lt"              then attr < value
    when "$gt"              then attr > value
    when "$lte"             then attr <= value
    when "$gte"             then attr >= value
    when "$between"         then value[0] < attr < value[1]
    when "$in"              then attr in value
    when "$nin"             then attr not in value
    when "$all"             then _(attr).all (item) -> item in value
    when "$any"             then _(attr).any (item) -> item in value
    when "$size"            then attr.length is value
    when "$exists", "$has"  then attr? is value
    when "$like"            then attr.indexOf(value) isnt -1
    when "$likeI"           then attr.toLowerCase().indexOf(value.toLowerCase()) isnt -1
    when "$regex"           then value.test attr
    when "$cb"              then value.call model, attr
    else false


# The main iterator that actually applies the query
iterator = (models, query, andOr, filterReject) ->
  parsed_query = parse_query query
  # The collections filter or reject method is used to iterate through each model in the collection
  _[filterReject] models, (model) ->
    # For each model in the collection, iterate through the supplied queries
    for q in parsed_query
      # Retrieve the attribute value from the model
      attr = model.get(q.key)
      # Check if the attribute value is the right type (some operators need a string, or an array)
      test = test_model_attribute(q.type, attr)
      # If the attribute test is true, perform the query
      if test then test = perform_query q.type, q.value, attr, model
      # If the query is an "or" query than as soon as a match is found we return "true"
      # Whereas if the query is an "and" query then we return "false" as soon as a match isn't found.
      return andOr if andOr is test

    # For an "or" query, if all the queries are false, then we return false
    # For an "and" query, if all the queries are true, then we return true
    not andOr

# An object with or, and, nor and not methods
process_query =
  $and: (models, query) -> iterator models, query, false, "filter"
  $or: (models, query) -> iterator models, query, true, "filter"
  $nor: (models, query) -> iterator models, query, true, "reject"
  $not: (models, query) -> iterator models, query, false, "reject"


# This method attempts to retrieve the result from the cache.
# If no match is found in the cache, then the query is run and
# the results are saved in the cache
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

# This method get the unsorted results
get_models = (collection, query) ->

  # Iterate through the query keys to check for any of the compound methods
  # The resulting array will have "$and" and "$not" first as it is better to use these
  # operators first when performing a compound query as they are likely to return less results
  compound_query = _.intersection ["$and", "$not", "$or", "$nor"], _(query).keys()

  # Assign the collections models to a local variable to use in the following switch
  models = collection.models

  if compound_query.length is 0
    # If no compound methods are found then use the "and" iterator
    process_query.$and models, query
  else
    # Else iterate through the compound methods using underscore reduce
    # The reduce iterator takes an array of models, performs the query and returns
    # the matched models for the next query
    reduce_iterator = (memo, query_type) ->
      process_query[query_type] memo, query[query_type]

    _.reduce compound_query, reduce_iterator, models

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

# If used on the server, then Backbone and Underscore are loaded as modules
unless typeof require is 'undefined'
  _ ?= require 'underscore'
  Backbone ?= require 'backbone'

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

# On the server the new Query Collection is added to exports
unless typeof exports is "undefined"
  exports.QueryCollection = Backbone.QueryCollection