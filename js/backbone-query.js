(function() {
  var and_iterator, iterator, or_iterator, parse_query,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  parse_query = function(raw_query) {
    var key, o, query_param, type, value, _results;
    _results = [];
    for (key in raw_query) {
      query_param = raw_query[key];
      o = {
        key: key
      };
      if (_(query_param).isObject()) {
        for (type in query_param) {
          value = query_param[type];
          o.type = type;
          o.value = value;
        }
      } else if (_(query_param).isRegExp()) {
        o.type = "$regex";
        o.value = query_param;
      } else {
        o.type = "$equal";
        o.value = query_param;
      }
      _results.push(o);
    }
    return _results;
  };

  iterator = function(collection, query, andOr) {
    var parsed_query;
    parsed_query = parse_query(query);
    return collection.filter(function(model) {
      var q, _i, _len;
      for (_i = 0, _len = parsed_query.length; _i < _len; _i++) {
        q = parsed_query[_i];
        if (andOr === ((function() {
          var _ref, _ref2, _ref3;
          switch (q.type) {
            case "$equal":
              return model.get(q.key) === q.value;
            case "$contains":
              return _ref = q.value, __indexOf.call(model.get(q.key), _ref) >= 0;
            case "$ne":
              return model.get(q.key) !== q.value;
            case "$lt":
              return model.get(q.key) < q.value;
            case "$gt":
              return model.get(q.key) > q.value;
            case "$lte":
              return model.get(q.key) <= q.value;
            case "$gte":
              return model.get(q.key) >= q.value;
            case "$in":
              return _ref2 = model.get(q.key), __indexOf.call(q.value, _ref2) >= 0;
            case "$nin":
              return _ref3 = model.get(q.key), __indexOf.call(q.value, _ref3) < 0;
            case "$all":
              return _(model.get(q.key)).all(function(item) {
                return __indexOf.call(q.value, item) >= 0;
              });
            case "$size":
              return model.get(q.key).length === q.value;
            case "$exists":
            case "$has":
              return model.has(q.key) === q.value;
            case "$like":
              return model.get(q.key).indexOf(q.value) !== -1;
            case "$regex":
              return model.get(q.key).match(q.value);
          }
        })())) {
          return andOr;
        }
      }
      return !andOr;
    });
  };

  and_iterator = function(collection, query) {
    return iterator(collection, query, false);
  };

  or_iterator = function(collection, query) {
    return iterator(collection, query, true);
  };

  Backbone.QueryCollection = Backbone.Collection.extend({
    query: function(query) {
      var collection, compound_query, process_query, reduce_iterator, results, type;
      collection = this;
      process_query = {
        $and: function(query) {
          return and_iterator(collection, query);
        },
        $or: function(query) {
          return or_iterator(collection, query);
        },
        $nor: function(query) {
          return _.difference(collection.models, or_iterator(collection, query));
        },
        $not: function(query) {
          return _.difference(collection.models, and_iterator(collection, query));
        }
      };
      compound_query = _(query).chain().keys().intersection(["$or", "$and", "$nor", "$not"]).value();
      switch (compound_query.length) {
        case 0:
          return process_query.$and(query);
        case 1:
          type = compound_query[0];
          return process_query[type](query[type]);
        default:
          results = (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = compound_query.length; _i < _len; _i++) {
              type = compound_query[_i];
              _results.push(process_query[type](query[type]));
            }
            return _results;
          })();
          reduce_iterator = function(memo, result) {
            return memo = _.intersection(memo, result);
          };
          return _.reduce(_.rest(results), reduce_iterator, results[0]);
      }
    }
  });

}).call(this);
