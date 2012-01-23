(function() {
  var and_iterator, iterator, or_iterator, parse_query, process_query, test_query_value,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  parse_query = function(raw_query) {
    var key, o, query_param, type, value, _fn, _results;
    _results = [];
    for (key in raw_query) {
      query_param = raw_query[key];
      o = {
        key: key
      };
      if (_(query_param).isObject()) {
        _fn = function(type, value) {
          if (test_query_value(type, value)) {
            o.type = type;
            return o.value = value;
          }
        };
        for (type in query_param) {
          value = query_param[type];
          _fn(type, value);
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

  test_query_value = function(type, value) {
    switch (type) {
      case "$in":
      case "$nin":
      case "$all":
        return _(value).isArray();
      case "$size":
        return _(value).isNumber();
      case "$regex":
        return _(value).isRegExp();
      case "$like":
        return _(value).isString();
      case "$between":
        return _(value).isArray() && (value.length === 2);
      default:
        return true;
    }
  };

  iterator = function(collection, query, andOr) {
    var parsed_query;
    parsed_query = parse_query(query);
    return collection.filter(function(model) {
      var attr, q, _i, _len;
      for (_i = 0, _len = parsed_query.length; _i < _len; _i++) {
        q = parsed_query[_i];
        if (andOr === ((function() {
          var _ref, _ref2, _ref3, _ref4;
          switch (q.type) {
            case "$equal":
              return model.get(q.key) === q.value;
            case "$contains":
              attr = model.get(q.key);
              if (_(attr).isArray()) {
                return _ref = q.value, __indexOf.call(attr, _ref) >= 0;
              } else {
                return false;
              }
              break;
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
            case "$between":
              return (q.value[0] < (_ref2 = model.get(q.key)) && _ref2 < q.value[1]);
            case "$in":
              return _ref3 = model.get(q.key), __indexOf.call(q.value, _ref3) >= 0;
            case "$nin":
              return _ref4 = model.get(q.key), __indexOf.call(q.value, _ref4) < 0;
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

  process_query = {
    $and: function(collection, query) {
      return and_iterator(collection, query);
    },
    $or: function(collection, query) {
      return or_iterator(collection, query);
    },
    $nor: function(collection, query) {
      return _.difference(collection.models, or_iterator(collection, query));
    },
    $not: function(collection, query) {
      return _.difference(collection.models, and_iterator(collection, query));
    }
  };

  Backbone.QueryCollection = Backbone.Collection.extend({
    query: function(query, pager) {
      var collection, compound_query, end, models, reduce_iterator, results, start, type;
      if (pager == null) pager = false;
      collection = this;
      compound_query = _(query).chain().keys().intersection(["$or", "$and", "$nor", "$not"]).value();
      models = ((function() {
        switch (compound_query.length) {
          case 0:
            return process_query.$and(collection, query);
          case 1:
            type = compound_query[0];
            return process_query[type](collection, query[type]);
          default:
            results = (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = compound_query.length; _i < _len; _i++) {
                type = compound_query[_i];
                _results.push(process_query[type](collection, query[type]));
              }
              return _results;
            })();
            reduce_iterator = function(memo, result) {
              return memo = _.intersection(memo, result);
            };
            return _.reduce(_.rest(results), reduce_iterator, results[0]);
        }
      })());
      if (_(pager).isObject() && pager.limit) {
        if (pager.offset) {
          start = pager.offset;
        } else if (pager.page) {
          start = (pager.page - 1) * pager.limit;
        } else {
          start = 0;
        }
        end = start + pager.limit;
        console.log(start, end, models);
        return models.slice(start, end);
      } else {
        return models;
      }
    }
  });

}).call(this);
