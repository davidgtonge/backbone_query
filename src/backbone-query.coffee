###
Backbone Query - A lightweight query API for Backbone Collections
(c)2012 - Dave Tonge
May be freely distributed according to MIT license.
###

((define) -> define 'backbone-query', (require, exports) ->
  _ = require('underscore')
  Backbone = require('backbone')
  # This function parses the query and converts it into an array of objects.
  # Each object has a key (model property), type (query type - $gt, $like...) and value (mixed).
  parse_query = (raw_query) ->
    (for key, query_param of raw_query
      o = {key}
      # Test for Regexs as they can be supplied without an operator
      if _.isRegExp(query_param)
        o.type = "$regex"
        o.value = query_param
      # Nested compound queries
      else if key in ["$and", "$not", "$or", "$nor"]
        o.type = key
        o.value = query_param
      # If the query paramater is an object then extract the key and value
      else if _(query_param).isObject() and not _(query_param).isArray()
        for type, value of query_param
          # Before adding the query, its value is checked to make sure it is the right type
          if test_query_value type, value
            o.type = type
            switch type
              when "$elemMatch", "$relationMatch"
                o.value = parse_query value
              when "$computed"
                q = {}
                q[key] = value
                o.value = parse_query q
              else
                o.value = value
      # If the query_param is not an object or a regexp then revert to the default operator: $equal
      else
        o.type = "$equal"
        o.value = query_param

      # For "$equal" queries with arrays or objects we need to perform a deep equal
      if o.type is "$equal" and _(o.value).isObject() then o.type = "$oEqual"
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
      when "$contains", "$all", "$any", "$elemMatch" then _(value).isArray()
      when "$size"                      then _(value).isArray() or _(value).isString()
      when "$in", "$nin"                then value?
      when "$relationMatch"             then value? and value.models
      else true

  # Perform the actual query logic for each query and each model/attribute
  perform_query = (type, value, attr, model, key) ->
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
        # If the condition is satisfied, then `process_query` must return an unmodified collection
        # In other words: If a collection with one element is passed, then the size of the returned collection is one
        process_query[type]([model], value).length == 1
      else false


  # The main iterator that actually applies the query
  iterator = (models, query, andOr, filterFunction, subQuery = false) ->
    parsed_query = if subQuery then query else parse_query query
    # The collections filter or reject method is used to iterate through each model in the collection
    filterFunction models, (model) ->
      # For each model in the collection, iterate through the supplied queries
      for q in parsed_query
        # Retrieve the attribute value from the model
        attr = switch subQuery
          when "elemMatch" then model[q.key]
          when "computed" then model[q.key]()
          else
            if q.key in ["$and", "$or", "$nor", "$not"]
              q.key
            else
              model.get(q.key)
        # Check if the attribute value is the right type (some operators need a string, or an array)
        test = test_model_attribute(q.type, attr)
        # If the attribute test is true, perform the query
        if test then test = perform_query q.type, q.value, attr, model, q.key
        # If the query is an "or" query than as soon as a match is found we return "true"
        # Whereas if the query is an "and" query then we return "false" as soon as a match isn't found.
        return andOr if andOr is test

      # For an "or" query, if all the queries are false, then we return false
      # For an "and" query, if all the queries are true, then we return true
      not andOr

  # Custom Filter / Reject methods faster than underscore methods as use for loops
  # http://jsperf.com/filter-vs-for-loop2
  filter = (array, test) -> (val for val in array when test val)
  reject = (array, test) -> (val for val in array when not test val)
  detect = (array, test) ->
    for val in array
      return true if test val
    false

  # An object with or, and, nor and not methods
  process_query =
    $and: (models, query) -> iterator models, query, false, filter
    $or: (models, query) -> iterator models, query, true, filter
    $nor: (models, query) -> iterator models, query, true, reject
    $not: (models, query) -> iterator models, query, false, reject


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
    # Query using the "and" iterator.
    process_query.$and collection.models, query

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

    # Where method wraps query and returns a new collection
    where: (params, options = {})->
      new @constructor @query params, options

    # Helper method to reset the query cache
    # Defined as a separate method to make it easy to bind to collection's change/add/remove events
    reset_query_cache: -> @_query_cache = {}

  # On the server the new Query Collection is added to exports
  exports.QueryCollection = Backbone.QueryCollection
).call this, if typeof define == 'function' and define.amd then define else (id, factory) ->
  unless typeof exports is 'undefined'
    factory ((id) -> require id), exports
  else
    # Load Underscore and backbone. No need to export QueryCollection in an module-less environment
    factory ((id) -> this[if id == 'underscore' then '_' else 'Backbone']), {}
  return
  