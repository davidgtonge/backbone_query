
/*
Backbone Query - A lightweight query API for Backbone Collections
(c)2012 - Dave Tonge
May be freely distributed according to MIT license.
*/

(function() {
  var and_iterator, array_intersection, get_models, iterator, or_iterator, page_models, parse_query, process_query, sort_models, test_query_value,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  array_intersection = function(arrays) {
    var rest;
    rest = _.rest(arrays);
    return _.filter(_.uniq(arrays[0]), function(item) {
      return _.every(rest, function(other) {
        return _.indexOf(other, item) >= 0;
      });
    });
  };

  parse_query = function(raw_query) {
    var key, o, query_param, type, value, _results;
    _results = [];
    for (key in raw_query) {
      query_param = raw_query[key];
      o = {
        key: key
      };
      if (_.isRegExp(query_param)) {
        o.type = "$regex";
        o.value = query_param;
      } else if (_(query_param).isObject()) {
        for (type in query_param) {
          value = query_param[type];
          if (test_query_value(type, value)) {
            o.type = type;
            o.value = value;
          }
        }
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
      case "$any":
        return _(value).isArray();
      case "$size":
        return _(value).isNumber();
      case "$regex":
        return _(value).isRegExp();
      case "$like":
        return _(value).isString();
      case "$between":
        return _(value).isArray() && (value.length === 2);
      case "$cb":
        return _(value).isFunction();
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
        attr = model.get(q.key);
        if (andOr === ((function() {
          var _ref;
          switch (q.type) {
            case "$equal":
              return attr === q.value;
            case "$contains":
              if (_(attr).isArray()) {
                return _ref = q.value, __indexOf.call(attr, _ref) >= 0;
              } else {
                return false;
              }
              break;
            case "$ne":
              return attr !== q.value;
            case "$lt":
              return attr < q.value;
            case "$gt":
              return attr > q.value;
            case "$lte":
              return attr <= q.value;
            case "$gte":
              return attr >= q.value;
            case "$between":
              return (q.value[0] < attr && attr < q.value[1]);
            case "$in":
              return __indexOf.call(q.value, attr) >= 0;
            case "$nin":
              return __indexOf.call(q.value, attr) < 0;
            case "$all":
              if (_(attr).isArray()) {
                return _(model.get(q.key)).all(function(item) {
                  return __indexOf.call(q.value, item) >= 0;
                });
              }
              break;
            case "$any":
              if (_(attr).isArray()) {
                return _(model.get(q.key)).any(function(item) {
                  return __indexOf.call(q.value, item) >= 0;
                });
              }
              break;
            case "$size":
              return attr.length === q.value;
            case "$exists":
            case "$has":
              return model.has(q.key) === q.value;
            case "$like":
              return attr.indexOf(q.value) !== -1;
            case "$regex":
              return q.value.test(attr);
            case "$cb":
              return q.value(attr);
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

  get_models = function(collection, query) {
    var compound_query, results, type;
    compound_query = _(query).chain().keys().intersection(["$or", "$and", "$nor", "$not"]).value();
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
        return array_intersection(results);
    }
  };

  sort_models = function(models, options) {
    if (_(options.sortBy).isString()) {
      models = _(models).sortBy(function(model) {
        return model.get(options.sortBy);
      });
    } else if (_(options.sortBy).isFunction()) {
      models = _(models).sortBy(options.sortBy);
    }
    if (options.order === "desc") models = models.reverse();
    return models;
  };

  page_models = function(models, options) {
    var end, start;
    if (options.offset) {
      start = options.offset;
    } else if (options.page) {
      start = (options.page - 1) * options.limit;
    } else {
      start = 0;
    }
    end = start + options.limit;
    return models.slice(start, end);
  };

  Backbone.QueryCollection = Backbone.Collection.extend({
    query: function(query, options) {
      var models;
      if (options == null) options = false;
      models = get_models(this, query);
      if (_(options).isObject()) {
        if (options.sortBy) models = sort_models(models, options);
        if (options.limit) models = page_models(models, options);
      }
      return models;
    }
  });

}).call(this);
