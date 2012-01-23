# This function parses the query and converts it into an array of objects.
# Each object has a key (model property), type (query type - $gt, $like...) and value.
parse_query = (raw_query) ->
  (for key, query_param of raw_query
    o = {key}

    # First we test if the param is a regular expression
    if _.isRegExp(query_param)
      o.type = "$regex"
      o.value = query_param
  # If the query paramater is an object then extract the key and value
    else if _(query_param).isObject()
      for type, value of query_param
        if test_query_value type, value
          o.type = type
          o.value = value

    else # Default query type is $equal
      o.type = "$equal"
      o.value = query_param
    o)

# Here we ensure that the correct query value is provided
test_query_value = (type, value) ->
  switch type
    when "$in","$nin","$all" then _(value).isArray()
    when "$size" then _(value).isNumber()
    when "$regex" then _(value).isRegExp()
    when "$like" then _(value).isString()
    when "$between" then _(value).isArray() and (value.length is 2)
    when "$cb" then _(value).isFunction()
    else true


iterator = (collection, query, andOr) ->
  parsed_query = parse_query query
  # We use the collections filter method to iterate through the model's collections
  collection.filter (model) ->
    # For each model in the collection we iterate through the supplied queries
    for q in parsed_query
      # If the query is an "or" query than as soon as a match is found we return "true"
      # Whereas if the query is an "and" query then we return "false" as soon as a match isn't found.
      return andOr if andOr is (switch q.type
        when "$equal" then model.get(q.key) is q.value
        when "$contains"
          #For this method we need to check that the model attribute is an array before we attempt to loop through it
          attr = model.get(q.key)
          if _(attr).isArray() then (q.value in attr) else false
        when "$ne" then model.get(q.key) isnt q.value
        when "$lt" then model.get(q.key) < q.value
        when "$gt" then model.get(q.key) > q.value
        when "$lte" then model.get(q.key) <= q.value
        when "$gte" then model.get(q.key) >= q.value
        when "$between" then q.value[0] < model.get(q.key) < q.value[1]
        when "$in" then  model.get(q.key) in q.value
        when "$nin" then  model.get(q.key) not in q.value
        when "$all"
          attr = model.get(q.key)
          if _(attr).isArray()
            _(model.get q.key).all (item) -> item in q.value
        when "$size" then model.get(q.key).length is q.value
        when "$exists", "$has" then model.has(q.key) is q.value
        when "$like" then model.get(q.key).indexOf(q.value) isnt -1
        when "$regex" then q.value.test model.get(q.key)
        when "$cb" then q.value model.get(q.key))
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

get_models = (collection, query) ->
  # We iterate through the query keys to check for any of the compound methods
  compound_query = _(query).chain().keys().intersection(["$or", "$and", "$nor", "$not"]).value()

  (switch compound_query.length
    # If no compound methods are found we use the "and" iterator
    when 0 then process_query.$and collection, query

    # If only 1 compound method we invoke just that method
    when 1
      type = compound_query[0]
      process_query[type] collection, query[type]

    # If more than 1 method is found, we process each of the methods
    else
      results = (for type in compound_query
        process_query[type] collection, query[type])

    # We now need to find the models that are in present in all result sets
    # As we have an unknown number of result sets, we use the reduce iterator together with underscores "intersection"
      reduce_iterator = (memo, result) ->
        memo = _.intersection memo, result

    # Here the reduce iterator is called, passing in the first result set as the initial memo
      _.reduce _.rest(results), reduce_iterator, results[0])

sort_models = (models, options) ->
  if _(options.sortBy).isString()
    models = _(models).sortBy (model) -> model.get(options.sortBy)
  else if _(options.sortBy).isFunction()
    models = _(models).sortBy(options.sortBy)

  if options.order is "desc" then models = models.reverse()

  models

page_models = (models, options) ->
  # Expects object in the form: {limit: num, offset: num or page: num
  if options.offset then start = options.offset
  else if options.page then start = (options.page - 1) * options.limit
  else start = 0

  end = start + options.limit
  models[start...end]



Backbone.QueryCollection = Backbone.Collection.extend

  # The main query method
  query: (query, options = false) ->

    # Retrieve the match models using the supplied query
    models = get_models @, query

    if _(options).isObject()
      # If a sortBy param is specified then sort the results
      if options.sortBy then models = sort_models models, options
      # If a limit param is specified than slice the results
      if options.limit then models = page_models models, options

    # Return the results
    models