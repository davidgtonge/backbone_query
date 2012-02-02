
/*
Backbone Query - A lightweight query API for Backbone Collections
(c)2012 - Dave Tonge
May be freely distributed according to MIT license.
*/

(function() {
  var array_intersection, get_cache, get_models, get_sorted_models, iterator, page_models, parse_query, process_query, sort_models, test_model_attribute, test_query_value,
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

  test_model_attribute = function(type, value) {
    switch (type) {
      case "$like":
      case "$regex":
        return _(value).isString();
      case "$contains":
      case "$all":
      case "$any":
        return _(value).isArray();
      case "$size":
        return _(value).isArray() || _(value).isString();
      case "$in":
      case "$nin":
        return value != null;
      default:
        return true;
    }
  };

  iterator = function(collection, query, andOr, filterReject) {
    var parsed_query;
    parsed_query = parse_query(query);
    return collection[filterReject](function(model) {
      var attr, q, test, _i, _len;
      for (_i = 0, _len = parsed_query.length; _i < _len; _i++) {
        q = parsed_query[_i];
        attr = model.get(q.key);
        test = test_model_attribute(q.type, attr);
        if (test) {
          test = ((function() {
            var _ref;
            switch (q.type) {
              case "$equal":
                return attr === q.value;
              case "$contains":
                return _ref = q.value, __indexOf.call(attr, _ref) >= 0;
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
                return _(model.get(q.key)).all(function(item) {
                  return __indexOf.call(q.value, item) >= 0;
                });
              case "$any":
                return _(model.get(q.key)).any(function(item) {
                  return __indexOf.call(q.value, item) >= 0;
                });
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
                return q.value.call(model, attr);
            }
          })());
        }
        if (andOr === test) return andOr;
      }
      return !andOr;
    });
  };

  process_query = {
    $and: function(collection, query) {
      return iterator(collection, query, false, "filter");
    },
    $or: function(collection, query) {
      return iterator(collection, query, true, "filter");
    },
    $nor: function(collection, query) {
      return iterator(collection, query, true, "reject");
    },
    $not: function(collection, query) {
      return iterator(collection, query, false, "reject");
    }
  };

  get_cache = function(collection, query, options) {
    var cache, models, query_string, _ref;
    query_string = JSON.stringify(query);
    cache = (_ref = collection._query_cache) != null ? _ref : collection._query_cache = {};
    models = cache[query_string];
    if (!models) {
      models = get_sorted_models(collection, query, options);
      cache[query_string] = models;
    }
    return models;
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

  get_sorted_models = function(collection, query, options) {
    var models;
    models = get_models(collection, query);
    if (options.sortBy) models = sort_models(models, options);
    return models;
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
    var end, sliced_models, start, total_pages;
    if (options.offset) {
      start = options.offset;
    } else if (options.page) {
      start = (options.page - 1) * options.limit;
    } else {
      start = 0;
    }
    end = start + options.limit;
    sliced_models = models.slice(start, end);
    if (options.pager && _.isFunction(options.pager)) {
      total_pages = Math.ceil(models.length / options.limit);
      options.pager(total_pages, sliced_models);
    }
    return sliced_models;
  };

  if (typeof require !== 'undefined') {
    if (typeof _ === "undefined" || _ === null) _ = require('underscore');
    if (typeof Backbone === "undefined" || Backbone === null) {
      Backbone = require('backbone');
    }
  }

  Backbone.QueryCollection = Backbone.Collection.extend({
    query: function(query, options) {
      var models;
      if (options == null) options = {};
      if (options.cache) {
        models = get_cache(this, query, options);
      } else {
        models = get_sorted_models(this, query, options);
      }
      if (options.limit) models = page_models(models, options);
      return models;
    },
    reset_query_cache: function() {
      return this._query_cache = {};
    }
  });

  if (typeof exports !== "undefined") {
    exports.QueryCollection = Backbone.QueryCollection;
  }

}).call(this);
