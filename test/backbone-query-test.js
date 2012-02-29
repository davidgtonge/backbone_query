(function() {
  var QueryCollection, create, equals;

  if (typeof require !== "undefined") {
    QueryCollection = require("../js/backbone-query.js").QueryCollection;
  } else {
    QueryCollection = Backbone.QueryCollection;
  }

  equals = [];

  if (typeof test === "undefined" || test === null) {
    test = function(name, test_cb) {
      return exports[name] = function(testObj) {
        var result, _i, _len;
        equals = [];
        test_cb();
        for (_i = 0, _len = equals.length; _i < _len; _i++) {
          result = equals[_i];
          testObj.equal(result[0], result[1]);
        }
        return testObj.done();
      };
    };
  }

  if (typeof equal === "undefined" || equal === null) {
    equal = function(real, expected) {
      return equals.push([real, expected]);
    };
  }

  create = function() {
    return new QueryCollection([
      {
        title: "Home",
        colors: ["red", "yellow", "blue"],
        likes: 12,
        featured: true,
        content: "Dummy content about coffeescript"
      }, {
        title: "About",
        colors: ["red"],
        likes: 2,
        featured: true,
        content: "dummy content about javascript"
      }, {
        title: "Contact",
        colors: ["red", "blue"],
        likes: 20,
        content: "Dummy content about PHP"
      }
    ]);
  };

  test("Equals query", function() {
    var a, result;
    a = create();
    result = a.query({
      title: "Home"
    });
    equal(result.length, 1);
    equal(result[0].get("title"), "Home");
    result = a.query({
      colors: "blue"
    });
    equal(result.length, 2);
    result = a.query({
      colors: ["red", "blue"]
    });
    return equal(result.length, 1);
  });

  test("Simple equals query (no results)", function() {
    var a, result;
    a = create();
    result = a.query({
      title: "Homes"
    });
    return equal(result.length, 0);
  });

  test("Simple equals query with explicit $equal", function() {
    var a, result;
    a = create();
    result = a.query({
      title: {
        $equal: "About"
      }
    });
    equal(result.length, 1);
    return equal(result[0].get("title"), "About");
  });

  test("$contains operator", function() {
    var a, result;
    a = create();
    result = a.query({
      colors: {
        $contains: "blue"
      }
    });
    return equal(result.length, 2);
  });

  test("$ne operator", function() {
    var a, result;
    a = create();
    result = a.query({
      title: {
        $ne: "Home"
      }
    });
    return equal(result.length, 2);
  });

  test("$lt operator", function() {
    var a, result;
    a = create();
    result = a.query({
      likes: {
        $lt: 12
      }
    });
    equal(result.length, 1);
    return equal(result[0].get("title"), "About");
  });

  test("$lte operator", function() {
    var a, result;
    a = create();
    result = a.query({
      likes: {
        $lte: 12
      }
    });
    return equal(result.length, 2);
  });

  test("$gt operator", function() {
    var a, result;
    a = create();
    result = a.query({
      likes: {
        $gt: 12
      }
    });
    equal(result.length, 1);
    return equal(result[0].get("title"), "Contact");
  });

  test("$gte operator", function() {
    var a, result;
    a = create();
    result = a.query({
      likes: {
        $gte: 12
      }
    });
    return equal(result.length, 2);
  });

  test("$between operator", function() {
    var a, result;
    a = create();
    result = a.query({
      likes: {
        $between: [1, 5]
      }
    });
    equal(result.length, 1);
    return equal(result[0].get("title"), "About");
  });

  test("$in operator", function() {
    var a, result;
    a = create();
    result = a.query({
      title: {
        $in: ["Home", "About"]
      }
    });
    return equal(result.length, 2);
  });

  test("$in operator with wrong query value", function() {
    var a, result;
    a = create();
    result = a.query({
      title: {
        $in: "Home"
      }
    });
    return equal(result.length, 0);
  });

  test("$nin operator", function() {
    var a, result;
    a = create();
    result = a.query({
      title: {
        $nin: ["Home", "About"]
      }
    });
    equal(result.length, 1);
    return equal(result[0].get("title"), "Contact");
  });

  test("$all operator", function() {
    var a, result;
    a = create();
    result = a.query({
      colors: {
        $all: ["red", "blue"]
      }
    });
    return equal(result.length, 2);
  });

  test("$all operator (wrong values)", function() {
    var a, result;
    a = create();
    result = a.query({
      title: {
        $all: ["red", "blue"]
      }
    });
    equal(result.length, 0);
    result = a.query({
      colors: {
        $all: "red"
      }
    });
    return equal(result.length, 0);
  });

  test("$any operator", function() {
    var a, result;
    a = create();
    result = a.query({
      colors: {
        $any: ["red", "blue"]
      }
    });
    equal(result.length, 3);
    result = a.query({
      colors: {
        $any: ["yellow", "blue"]
      }
    });
    return equal(result.length, 2);
  });

  test("$size operator", function() {
    var a, result;
    a = create();
    result = a.query({
      colors: {
        $size: 3
      }
    });
    equal(result.length, 1);
    return equal(result[0].get("title"), "Home");
  });

  test("$exists operator", function() {
    var a, result;
    a = create();
    result = a.query({
      featured: {
        $exists: true
      }
    });
    return equal(result.length, 2);
  });

  test("$has operator", function() {
    var a, result;
    a = create();
    result = a.query({
      featured: {
        $exists: false
      }
    });
    equal(result.length, 1);
    return equal(result[0].get("title"), "Contact");
  });

  test("$like operator", function() {
    var a, result;
    a = create();
    result = a.query({
      content: {
        $like: "javascript"
      }
    });
    equal(result.length, 1);
    return equal(result[0].get("title"), "About");
  });

  test("$like operator 2", function() {
    var a, result;
    a = create();
    result = a.query({
      content: {
        $like: "content"
      }
    });
    return equal(result.length, 3);
  });

  test("$likeI operator", function() {
    var a, result;
    a = create();
    result = a.query({
      content: {
        $likeI: "dummy"
      }
    });
    equal(result.length, 3);
    result = a.query({
      content: {
        $like: "dummy"
      }
    });
    return equal(result.length, 1);
  });

  test("$regex", function() {
    var a, result;
    a = create();
    result = a.query({
      content: {
        $regex: /javascript/gi
      }
    });
    equal(result.length, 1);
    return equal(result[0].get("title"), "About");
  });

  test("$regex2", function() {
    var a, result;
    a = create();
    result = a.query({
      content: {
        $regex: /dummy/
      }
    });
    return equal(result.length, 1);
  });

  test("$regex3", function() {
    var a, result;
    a = create();
    result = a.query({
      content: {
        $regex: /dummy/i
      }
    });
    return equal(result.length, 3);
  });

  test("$regex4", function() {
    var a, result;
    a = create();
    result = a.query({
      content: /javascript/i
    });
    return equal(result.length, 1);
  });

  test("$cb - callback", function() {
    var a, result;
    a = create();
    result = a.query({
      title: {
        $cb: function(attr) {
          return attr.charAt(0).toLowerCase() === "c";
        }
      }
    });
    equal(result.length, 1);
    return equal(result[0].get("title"), "Contact");
  });

  test("$cb - callback - checking 'this' is the model", function() {
    var a, result;
    a = create();
    result = a.query({
      title: {
        $cb: function(attr) {
          return this.get("title") === "Home";
        }
      }
    });
    equal(result.length, 1);
    return equal(result[0].get("title"), "Home");
  });

  test("$and operator", function() {
    var a, result;
    a = create();
    result = a.query({
      likes: {
        $gt: 5
      },
      colors: {
        $contains: "yellow"
      }
    });
    equal(result.length, 1);
    return equal(result[0].get("title"), "Home");
  });

  test("$and operator (explicit)", function() {
    var a, result;
    a = create();
    result = a.query({
      $and: {
        likes: {
          $gt: 5
        },
        colors: {
          $contains: "yellow"
        }
      }
    });
    equal(result.length, 1);
    return equal(result[0].get("title"), "Home");
  });

  test("$or operator", function() {
    var a, result;
    a = create();
    result = a.query({
      $or: {
        likes: {
          $gt: 5
        },
        colors: {
          $contains: "yellow"
        }
      }
    });
    return equal(result.length, 2);
  });

  test("$nor operator", function() {
    var a, result;
    a = create();
    result = a.query({
      $nor: {
        likes: {
          $gt: 5
        },
        colors: {
          $contains: "yellow"
        }
      }
    });
    equal(result.length, 1);
    return equal(result[0].get("title"), "About");
  });

  test("Compound Queries", function() {
    var a, result;
    a = create();
    result = a.query({
      $and: {
        likes: {
          $gt: 5
        }
      },
      $or: {
        content: {
          $like: "PHP"
        },
        colors: {
          $contains: "yellow"
        }
      }
    });
    equal(result.length, 2);
    result = a.query({
      $and: {
        likes: {
          $lt: 15
        }
      },
      $or: {
        content: {
          $like: "Dummy"
        },
        featured: {
          $exists: true
        }
      },
      $not: {
        colors: {
          $contains: "yellow"
        }
      }
    });
    equal(result.length, 1);
    return equal(result[0].get("title"), "About");
  });

  test("Limit", function() {
    var a, result;
    a = create();
    result = a.query({
      likes: {
        $gt: 1
      }
    }, {
      limit: 2
    });
    return equal(result.length, 2);
  });

  test("Offset", function() {
    var a, result;
    a = create();
    result = a.query({
      likes: {
        $gt: 1
      }
    }, {
      limit: 2,
      offset: 2
    });
    return equal(result.length, 1);
  });

  test("Page", function() {
    var a, result;
    a = create();
    result = a.query({
      likes: {
        $gt: 1
      }
    }, {
      limit: 3,
      page: 2
    });
    return equal(result.length, 0);
  });

  test("Sorder by model key", function() {
    var a, result;
    a = create();
    result = a.query({
      likes: {
        $gt: 1
      }
    }, {
      sortBy: "likes"
    });
    equal(result.length, 3);
    equal(result[0].get("title"), "About");
    equal(result[1].get("title"), "Home");
    return equal(result[2].get("title"), "Contact");
  });

  test("Sorder by model key with descending order", function() {
    var a, result;
    a = create();
    result = a.query({
      likes: {
        $gt: 1
      }
    }, {
      sortBy: "likes",
      order: "desc"
    });
    equal(result.length, 3);
    equal(result[2].get("title"), "About");
    equal(result[1].get("title"), "Home");
    return equal(result[0].get("title"), "Contact");
  });

  test("Sorder by function", function() {
    var a, result;
    a = create();
    result = a.query({
      likes: {
        $gt: 1
      }
    }, {
      sortBy: function(model) {
        return model.get("title").charAt(2);
      }
    });
    equal(result.length, 3);
    equal(result[2].get("title"), "About");
    equal(result[0].get("title"), "Home");
    return equal(result[1].get("title"), "Contact");
  });

  test("cache", function() {
    var a, result;
    a = create();
    result = a.query({
      likes: {
        $gt: 1
      }
    }, {
      cache: true,
      sortBy: function(model) {
        return model.get("title").charAt(2);
      }
    });
    equal(result.length, 3);
    result = a.query({
      likes: {
        $gt: 1
      }
    }, {
      cache: true,
      sortBy: function(model) {
        return model.get("title").charAt(2);
      }
    });
    equal(result.length, 3);
    a.remove(result[0]);
    result = a.query({
      likes: {
        $gt: 1
      }
    }, {
      sortBy: function(model) {
        return model.get("title").charAt(2);
      }
    });
    equal(result.length, 2);
    result = a.query({
      likes: {
        $gt: 1
      }
    }, {
      cache: true,
      sortBy: function(model) {
        return model.get("title").charAt(2);
      }
    });
    return equal(result.length, 3);
  });

  test("cache with multiple collections", function() {
    var a, a_result, b, b_result;
    a = create();
    b = create();
    b.remove(b.at(0));
    equal(b.length, 2);
    equal(a.length, 3);
    a_result = a.query({
      likes: {
        $gt: 1
      }
    }, {
      cache: true,
      sortBy: function(model) {
        return model.get("title").charAt(2);
      }
    });
    equal(a_result.length, 3);
    b_result = b.query({
      likes: {
        $gt: 1
      }
    }, {
      cache: true,
      sortBy: function(model) {
        return model.get("title").charAt(2);
      }
    });
    equal(b_result.length, 2);
    a.remove(a_result[0]);
    b.remove(b_result[0]);
    a_result = a.query({
      likes: {
        $gt: 1
      }
    }, {
      cache: true,
      sortBy: function(model) {
        return model.get("title").charAt(2);
      }
    });
    equal(a_result.length, 3);
    equal(a.length, 2);
    b_result = b.query({
      likes: {
        $gt: 1
      }
    }, {
      cache: true,
      sortBy: function(model) {
        return model.get("title").charAt(2);
      }
    });
    equal(b_result.length, 2);
    equal(b.length, 1);
    a.reset_query_cache();
    a_result = a.query({
      likes: {
        $gt: 1
      }
    }, {
      cache: true,
      sortBy: function(model) {
        return model.get("title").charAt(2);
      }
    });
    equal(a_result.length, 2);
    equal(a.length, 2);
    b_result = b.query({
      likes: {
        $gt: 1
      }
    }, {
      cache: true,
      sortBy: function(model) {
        return model.get("title").charAt(2);
      }
    });
    equal(b_result.length, 2);
    return equal(b.length, 1);
  });

  test("null attribute with various operators", function() {
    var a, result;
    a = create();
    result = a.query({
      wrong_key: {
        $like: "test"
      }
    });
    equal(result.length, 0);
    result = a.query({
      wrong_key: {
        $regex: /test/
      }
    });
    equal(result.length, 0);
    result = a.query({
      wrong_key: {
        $contains: "test"
      }
    });
    equal(result.length, 0);
    result = a.query({
      wrong_key: {
        $all: [12, 23]
      }
    });
    equal(result.length, 0);
    result = a.query({
      wrong_key: {
        $any: [12, 23]
      }
    });
    equal(result.length, 0);
    result = a.query({
      wrong_key: {
        $size: 10
      }
    });
    equal(result.length, 0);
    result = a.query({
      wrong_key: {
        $in: [12, 23]
      }
    });
    equal(result.length, 0);
    result = a.query({
      wrong_key: {
        $nin: [12, 23]
      }
    });
    return equal(result.length, 0);
  });

  test("Where method", function() {
    var a, result;
    a = create();
    result = a.where({
      likes: {
        $gt: 5
      }
    });
    equal(result.length, 2);
    return equal(result.models.length, result.length);
  });

  test("$elemMatch", function() {
    var a, b, result, text_search;
    a = new QueryCollection([
      {
        title: "Home",
        comments: [
          {
            text: "I like this post"
          }, {
            text: "I love this post"
          }, {
            text: "I hate this post"
          }
        ]
      }, {
        title: "About",
        comments: [
          {
            text: "I like this page"
          }, {
            text: "I love this page"
          }, {
            text: "I really like this page"
          }
        ]
      }
    ]);
    b = new QueryCollection([
      {
        foo: [
          {
            shape: "square",
            color: "purple",
            thick: false
          }, {
            shape: "circle",
            color: "red",
            thick: true
          }
        ]
      }, {
        foo: [
          {
            shape: "square",
            color: "red",
            thick: true
          }, {
            shape: "circle",
            color: "purple",
            thick: false
          }
        ]
      }
    ]);
    text_search = {
      $likeI: "love"
    };
    result = a.query({
      $or: {
        comments: {
          $elemMatch: {
            text: text_search
          }
        },
        title: text_search
      }
    });
    equal(result.length, 2);
    result = a.query({
      $or: {
        comments: {
          $elemMatch: {
            text: /post/
          }
        }
      }
    });
    equal(result.length, 1);
    result = a.query({
      $or: {
        comments: {
          $elemMatch: {
            text: /post/
          }
        },
        title: /about/i
      }
    });
    equal(result.length, 2);
    result = a.query({
      $or: {
        comments: {
          $elemMatch: {
            text: /really/
          }
        }
      }
    });
    equal(result.length, 1);
    result = b.query({
      foo: {
        $elemMatch: {
          shape: "square",
          color: "purple"
        }
      }
    });
    return equal(result.length, 1);
  });

}).call(this);
