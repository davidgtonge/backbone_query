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
        # Before adding the query, its value is checked to make sure it is the right type
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
    when "$in","$nin","$all", "$any" then _(value).isArray()
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
      attr = model.get(q.key)
      # If the query is an "or" query than as soon as a match is found we return "true"
      # Whereas if the query is an "and" query then we return "false" as soon as a match isn't found.
      return andOr if andOr is (switch q.type
        when "$equal" then attr is q.value
        when "$contains"
          #For this method we need to check that the model attribute is an array before we attempt to loop through it
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
          if _(attr).isArray()
            _(model.get q.key).all (item) -> item in q.value
        when "$any"
          if _(attr).isArray()
            _(model.get q.key).any (item) -> item in q.value
        when "$size" then attr.length is q.value
        when "$exists", "$has" then model.has(q.key) is q.value
        when "$like" then attr.indexOf(q.value) isnt -1
        when "$regex" then q.value.test attr
        when "$cb" then q.value attr)
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

page_models = (models, options) ->
  # Expects object in the form: {limit: num, offset: num or page: num}
  if options.offset then start = options.offset
  else if options.page then start = (options.page - 1) * options.limit
  else start = 0

  end = start + options.limit
  # The results are sliced according to the calculated start and end params
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