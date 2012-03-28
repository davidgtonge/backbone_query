
/*
Backbone Query - A lightweight query API for Backbone Collections
(c)2012 - Dave Tonge
May be freely distributed according to MIT license.
*/

(function() {
  var detect, filter, get_cache, get_models, get_sorted_models, iterator, page_models, parse_query, perform_query, process_query, reject, sort_models, test_model_attribute, test_query_value,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  parse_query = function(raw_query) {
    var key, o, q, query_param, type, value, _results;
    _results = [];
    for (key in raw_query) {
      query_param = raw_query[key];
      o = {
        key: key
      };
      if (_.isRegExp(query_param)) {
        o.type = "$regex";
        o.value = query_param;
      } else if (_(query_param).isObject() && !_(query_param).isArray()) {
        for (type in query_param) {
          value = query_param[type];
          if (test_query_value(type, value)) {
            o.type = type;
            switch (type) {
              case "$elemMatch":
              case "$relationMatch":
                o.value = parse_query(value);
                break;
              case "$computed":
                q = {};
                q[key] = value;
                o.value = parse_query(q);
                break;
              default:
                o.value = value;
            }
          }
        }
      } else {
        o.type = "$equal";
        o.value = query_param;
      }
      if (o.type === "$equal" && _(o.value).isObject()) o.type = "$oEqual";
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
      case "$likeI":
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
      case "$likeI":
      case "$regex":
        return _(value).isString();
      case "$contains":
      case "$all":
      case "$any":
      case "$elemMatch":
        return _(value).isArray();
      case "$size":
        return _(value).isArray() || _(value).isString();
      case "$in":
      case "$nin":
        return value != null;
      case "$relationMatch":
        return (value != null) && value.models;
      default:
        return true;
    }
  };

  perform_query = function(type, value, attr, model, key) {
    switch (type) {
      case "$equal":
        if (_(attr).isArray()) {
          return __indexOf.call(attr, value) >= 0;
        } else {
          return attr === value;
        }
        break;
      case "$oEqual":
        return _(attr).isEqual(value);
      case "$contains":
        return __indexOf.call(attr, value) >= 0;
      case "$ne":
        return attr !== value;
      case "$lt":
        return attr < value;
      case "$gt":
        return attr > value;
      case "$lte":
        return attr <= value;
      case "$gte":
        return attr >= value;
      case "$between":
        return (value[0] < attr && attr < value[1]);
      case "$in":
        return __indexOf.call(value, attr) >= 0;
      case "$nin":
        return __indexOf.call(value, attr) < 0;
      case "$all":
        return _(value).all(function(item) {
          return __indexOf.call(attr, item) >= 0;
        });
      case "$any":
        return _(attr).any(function(item) {
          return __indexOf.call(value, item) >= 0;
        });
      case "$size":
        return attr.length === value;
      case "$exists":
      case "$has":
        return (attr != null) === value;
      case "$like":
        return attr.indexOf(value) !== -1;
      case "$likeI":
        return attr.toLowerCase().indexOf(value.toLowerCase()) !== -1;
      case "$regex":
        return value.test(attr);
      case "$cb":
        return value.call(model, attr);
      case "$elemMatch":
        return iterator(attr, value, false, detect, "elemMatch");
      case "$relationMatch":
        return iterator(attr.models, value, false, detect, "relationMatch");
      case "$computed":
        return iterator([model], value, false, detect, "computed");
      default:
        return false;
    }
  };

  iterator = function(models, query, andOr, filterFunction, subQuery) {
    var parsed_query;
    if (subQuery == null) subQuery = false;
    parsed_query = subQuery ? query : parse_query(query);
    return filterFunction(models, function(model) {
      var attr, q, test, _i, _len;
      for (_i = 0, _len = parsed_query.length; _i < _len; _i++) {
        q = parsed_query[_i];
        attr = (function() {
          switch (subQuery) {
            case "elemMatch":
              return model[q.key];
            case "computed":
              return model[q.key]();
            default:
              return model.get(q.key);
          }
        })();
        test = test_model_attribute(q.type, attr);
        if (test) test = perform_query(q.type, q.value, attr, model, q.key);
        if (andOr === test) return andOr;
      }
      return !andOr;
    });
  };

  filter = function(array, test) {
    var val, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = array.length; _i < _len; _i++) {
      val = array[_i];
      if (test(val)) _results.push(val);
    }
    return _results;
  };

  reject = function(array, test) {
    var val, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = array.length; _i < _len; _i++) {
      val = array[_i];
      if (!test(val)) _results.push(val);
    }
    return _results;
  };

  detect = function(array, test) {
    var val, _i, _len;
    for (_i = 0, _len = array.length; _i < _len; _i++) {
      val = array[_i];
      if (test(val)) return true;
    }
    return false;
  };

  process_query = {
    $and: function(models, query) {
      return iterator(models, query, false, filter);
    },
    $or: function(models, query) {
      return iterator(models, query, true, filter);
    },
    $nor: function(models, query) {
      return iterator(models, query, true, reject);
    },
    $not: function(models, query) {
      return iterator(models, query, false, reject);
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
    var compound_query, models, reduce_iterator;
    compound_query = _.intersection(["$and", "$not", "$or", "$nor"], _(query).keys());
    models = collection.models;
    if (compound_query.length === 0) {
      return process_query.$and(models, query);
    } else {
      reduce_iterator = function(memo, query_type) {
        return process_query[query_type](memo, query[query_type]);
      };
      return _.reduce(compound_query, reduce_iterator, models);
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
    where: function(params, options) {
      if (options == null) options = {};
      return new this.constructor(this.query(params, options));
    },
    reset_query_cache: function() {
      return this._query_cache = {};
    }
  });

  if (typeof exports !== "undefined") {
    exports.QueryCollection = Backbone.QueryCollection;
  }

}).call(this);
