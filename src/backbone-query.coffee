# This function parses the query and converts it into an array of objects.
# Each object has a key (model property), type (query type - $gt, $like...) and value.
parse_query = (raw_query) ->
  (for key, query_param of raw_query
    o = {key}
  # If the query paramater is an object then extract the key and value
    if _(query_param).isObject()
      for type, value of query_param
        o.type = type
        o.value = value
      # If its not an object then check if its a regular expression
    else if _(query_param).isRegExp()
      o.type = "$regex"
      o.value = query_param
      # Default query type is $equal
    else
      o.type = "$equal"
      o.value = query_param
    o)

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
        when "$contains" then q.value in model.get(q.key)
        when "$ne" then model.get(q.key) isnt q.value
        when "$lt" then model.get(q.key) < q.value
        when "$gt" then model.get(q.key) > q.value
        when "$lte" then model.get(q.key) <= q.value
        when "$gte" then model.get(q.key) >= q.value
        when "$in" then  model.get(q.key) in q.value
        when "$nin" then  model.get(q.key) not in q.value
        when "$all" then  _(model.get q.key).all (item) -> item in q.value
        when "$size" then model.get(q.key).length is q.value
        when "$exists", "$has" then model.has(q.key) is q.value
        when "$like" then model.get(q.key).indexOf(q.value) isnt -1
        when "$regex" then  model.get(q.key).match(q.value))
    # For an "or" query, if all the queries are false, then we return false
    # For an "and" query, if all the queries are true, then we return true
    not andOr

and_iterator = (collection, query) -> iterator collection, query, false
or_iterator = (collection, query) -> iterator collection, query, true



Backbone.QueryCollection = Backbone.Collection.extend

  # The main query method
  query: (query) ->
    collection = @

    # A object is created with or, and and nor methods specific to the current query
    process_query =
      $and: (query) -> and_iterator collection, query
      $or: (query) -> or_iterator collection, query
      $nor: (query) -> _.difference collection.models, (or_iterator collection, query)
      $not: (query) -> _.difference collection.models, (and_iterator collection, query)

    # We iterate through the query keys to check for any of the compound methods
    compound_query = _(query).chain().keys().intersection(["$or", "$and", "$nor", "$not"]).value()

    switch compound_query.length
      # If no compound methods are found we use the "and" iterator
      when 0 then process_query.$and query
      # If only 1 compound method we invoke just that method
      when 1
        type = compound_query[0]
        process_query[type] query[type]
      # If more than 1 method is found, we process each of the methods
      else
        results = (for type in compound_query
          process_query[type] query[type])

        # We now need to find the models that are in present in all result sets
        # As we have an unknown number of result sets, we use the reduce iterator together with underscores "intersection"
        reduce_iterator = (memo, result) ->
          memo = _.intersection memo, result

        # Here the reduce iterator is called, passing in the first result set as the initial memo
        _.reduce _.rest(results), reduce_iterator, results[0]