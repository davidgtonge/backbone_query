
if typeof require isnt "undefined"
  {QueryCollection} = require "../js/backbone-query.js"
  Backbone = require "backbone"
else
  QueryCollection = window.Backbone.QueryCollection
  Backbone = window.Backbone

# Helper functions that turn Qunit tests into nodeunit tests
equals = []

test ?= (name, test_cb) ->
  exports[name] = (testObj) ->
    equals = []
    test_cb()
    for result in equals
      testObj.equal result[0], result[1]
    testObj.done()

equal ?= (real, expected) -> equals.push [real, expected]

create = ->
  new QueryCollection [
    {title:"Home", colors:["red","yellow","blue"], likes:12, featured:true, content: "Dummy content about coffeescript"}
    {title:"About", colors:["red"], likes:2, featured:true, content: "dummy content about javascript"}
    {title:"Contact", colors:["red","blue"], likes:20, content: "Dummy content about PHP"}
  ]


test "Equals query", ->
  a = create()
  result = a.query title:"Home"
  equal result.length, 1
  equal result[0].get("title"), "Home"

  result = a.query colors: "blue"
  equal result.length, 2

  result = a.query colors: ["red", "blue"]
  equal result.length, 1



test "Simple equals query (no results)", ->
  a = create()
  result = a.query title:"Homes"
  equal result.length, 0

test "Simple equals query with explicit $equal", ->
  a = create()
  result = a.query title: {$equal: "About"}
  equal result.length, 1
  equal result[0].get("title"), "About"

test "$contains operator", ->
  a = create()
  result = a.query colors: {$contains: "blue"}
  equal result.length, 2

test "$ne operator", ->
  a = create()
  result = a.query title: {$ne: "Home"}
  equal result.length, 2

test "$lt operator", ->
  a = create()
  result = a.query likes: {$lt: 12}
  equal result.length, 1
  equal result[0].get("title"), "About"

test "$lte operator", ->
  a = create()
  result = a.query likes: {$lte: 12}
  equal result.length, 2

test "$gt operator", ->
  a = create()
  result = a.query likes: {$gt: 12}
  equal result.length, 1
  equal result[0].get("title"), "Contact"

test "$gte operator", ->
  a = create()
  result = a.query likes: {$gte: 12}
  equal result.length, 2

test "$between operator", ->
  a = create()
  result = a.query likes: {$between: [1,5]}
  equal result.length, 1
  equal result[0].get("title"), "About"

test "$in operator", ->
  a = create()
  result = a.query title: {$in: ["Home","About"]}
  equal result.length, 2

test "$in operator with wrong query value", ->
  a = create()
  result = a.query title: {$in: "Home"}
  equal result.length, 0

test "$nin operator", ->
  a = create()
  result = a.query title: {$nin: ["Home","About"]}
  equal result.length, 1
  equal result[0].get("title"), "Contact"

test "$all operator", ->
  a = create()
  result = a.query colors: {$all: ["red","blue"]}
  equal result.length, 2

test "$all operator (wrong values)", ->
  a = create()
  result = a.query title: {$all: ["red","blue"]}
  equal result.length, 0

  result = a.query colors: {$all: "red"}
  equal result.length, 0

test "$any operator", ->
  a = create()
  result = a.query colors: {$any: ["red","blue"]}
  equal result.length, 3

  result = a.query colors: {$any: ["yellow","blue"]}
  equal result.length, 2

test "$size operator", ->
  a = create()
  result = a.query colors: {$size: 3}
  equal result.length, 1
  equal result[0].get("title"), "Home"

test "$exists operator", ->
  a = create()
  result = a.query featured: {$exists: true}
  equal result.length, 2

test "$has operator", ->
  a = create()
  result = a.query featured: {$exists: false}
  equal result.length, 1
  equal result[0].get("title"), "Contact"

test "$like operator", ->
  a = create()
  result = a.query content: {$like: "javascript"}
  equal result.length, 1
  equal result[0].get("title"), "About"

test "$like operator 2", ->
  a = create()
  result = a.query content: {$like: "content"}
  equal result.length, 3

test "$likeI operator", ->
  a = create()
  result = a.query content: {$likeI: "dummy"}
  equal result.length, 3
  result = a.query content: {$like: "dummy"}
  equal result.length, 1

test "$regex", ->
  a = create()
  result = a.query content: {$regex: /javascript/gi}
  equal result.length, 1
  equal result[0].get("title"), "About"

test "$regex2", ->
  a = create()
  result = a.query content: {$regex: /dummy/}
  equal result.length, 1

test "$regex3", ->
  a = create()
  result = a.query content: {$regex: /dummy/i}
  equal result.length, 3

test "$regex4", ->
  a = create()
  result = a.query content: /javascript/i
  equal result.length, 1

test "$cb - callback", ->
  a = create()
  result = a.query title: {$cb: (attr) -> attr.charAt(0).toLowerCase() is "c"}
  equal result.length, 1
  equal result[0].get("title"), "Contact"

test "$cb - callback - checking 'this' is the model", ->
  a = create()
  result = a.query title:
    $cb: (attr) -> @get("title") is "Home"
  equal result.length, 1
  equal result[0].get("title"), "Home"

test "$and operator", ->
  a = create()
  result = a.query likes: {$gt: 5}, colors: {$contains: "yellow"}
  equal result.length, 1
  equal result[0].get("title"), "Home"

test "$and operator (explicit)", ->
  a = create()
  result = a.query $and: {likes: {$gt: 5}, colors: {$contains: "yellow"}}
  equal result.length, 1
  equal result[0].get("title"), "Home"

test "$or operator", ->
  a = create()
  result = a.query $or: {likes: {$gt: 5}, colors: {$contains: "yellow"}}
  equal result.length, 2

test "$nor operator", ->
  a = create()
  result = a.query $nor: {likes: {$gt: 5}, colors: {$contains: "yellow"}}
  equal result.length, 1
  equal result[0].get("title"), "About"

test "Compound Queries", ->
  a = create()
  result = a.query $and: {likes: {$gt: 5}}, $or: {content: {$like: "PHP"},  colors: {$contains: "yellow"}}
  equal result.length, 2

  result = a.query
    $and:
      likes: $lt: 15
    $or:
      content:
        $like: "Dummy"
      featured:
        $exists:true
    $not:
      colors: $contains: "yellow"
  equal result.length, 1
  equal result[0].get("title"), "About"



test "Limit", ->
  a = create()
  result = a.query {likes: {$gt: 1}}, {limit:2}
  equal result.length, 2

test "Offset", ->
  a = create()
  result = a.query {likes: {$gt: 1}}, {limit:2, offset:2}
  equal result.length, 1

test "Page", ->
  a = create()
  result = a.query {likes: {$gt: 1}}, {limit:3, page:2}
  equal result.length, 0

test "Sorder by model key", ->
  a = create()
  result = a.query {likes: {$gt: 1}}, {sortBy:"likes"}
  equal result.length, 3
  equal result[0].get("title"), "About"
  equal result[1].get("title"), "Home"
  equal result[2].get("title"), "Contact"

test "Sorder by model key with descending order", ->
  a = create()
  result = a.query {likes: {$gt: 1}}, {sortBy:"likes", order:"desc"}
  equal result.length, 3
  equal result[2].get("title"), "About"
  equal result[1].get("title"), "Home"
  equal result[0].get("title"), "Contact"

test "Sorder by function", ->
  a = create()
  result = a.query {likes: {$gt: 1}}, {sortBy: (model) -> model.get("title").charAt(2) }
  equal result.length, 3
  equal result[2].get("title"), "About"
  equal result[0].get("title"), "Home"
  equal result[1].get("title"), "Contact"

test "cache", ->
  a = create()
  result = a.query {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
  equal result.length, 3
  result = a.query {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
  equal result.length, 3
  a.remove result[0]
  result = a.query {likes: {$gt: 1}}, {sortBy: (model) -> model.get("title").charAt(2) }
  equal result.length, 2
  result = a.query {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
  equal result.length, 3

test "cache with multiple collections", ->
  a = create()
  b = create()
  b.remove b.at(0)
  equal b.length, 2
  equal a.length, 3

  a_result = a.query {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
  equal a_result.length, 3
  b_result = b.query {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
  equal b_result.length, 2

  a.remove a_result[0]
  b.remove b_result[0]

  a_result = a.query {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
  equal a_result.length, 3
  equal a.length, 2
  b_result = b.query {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
  equal b_result.length, 2
  equal b.length, 1

  a.reset_query_cache()
  a_result = a.query {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
  equal a_result.length, 2
  equal a.length, 2

  b_result = b.query {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
  equal b_result.length, 2
  equal b.length, 1


test "null attribute with various operators", ->
  a = create()
  result = a.query wrong_key: {$like: "test"}
  equal result.length, 0
  result = a.query wrong_key: {$regex: /test/}
  equal result.length, 0
  result = a.query wrong_key: {$contains: "test"}
  equal result.length, 0
  result = a.query wrong_key: {$all: [12,23]}
  equal result.length, 0
  result = a.query wrong_key: {$any: [12,23]}
  equal result.length, 0
  result = a.query wrong_key: {$size: 10}
  equal result.length, 0
  result = a.query wrong_key: {$in: [12,23]}
  equal result.length, 0
  result = a.query wrong_key: {$nin: [12,23]}
  equal result.length, 0

test "Where method", ->
  a = create()
  result = a.where likes: $gt: 5
  equal result.length, 2
  equal result.models.length, result.length


test "$computed", ->
  class testModel extends Backbone.Model
    full_name: -> "#{@get 'first_name'} #{@get 'last_name'}"

  a = new testModel
    first_name: "Dave"
    last_name: "Tonge"
  b = new testModel
    first_name: "John"
    last_name: "Smith"
  c = new QueryCollection [a,b]

  result = c.query
    full_name: $computed: "Dave Tonge"

  equal result.length, 1
  equal result[0].get("first_name"), "Dave"

  result = c.query
    full_name: $computed: $likeI: "n sm"
  equal result.length, 1
  equal result[0].get("first_name"), "John"


test "$elemMatch", ->
  a = new QueryCollection [
    {title: "Home", comments:[
      {text:"I like this post"}
      {text:"I love this post"}
      {text:"I hate this post"}
    ]}
    {title: "About", comments:[
      {text:"I like this page"}
      {text:"I love this page"}
      {text:"I really like this page"}
    ]}
  ]

  b = new QueryCollection [
    {foo: [
      {shape: "square", color: "purple", thick: false}
      {shape: "circle", color: "red", thick: true}
    ]}
    {foo: [
      {shape: "square", color: "red", thick: true}
      {shape: "circle", color: "purple", thick: false}
    ]}
  ]

  text_search = {$likeI: "love"}

  result = a.query $or:
    comments:
      $elemMatch:
        text: text_search
    title: text_search
  equal result.length, 2

  result = a.query $or:
    comments:
      $elemMatch:
        text: /post/
  equal result.length, 1

  result = a.query $or:
    comments:
      $elemMatch:
        text: /post/
    title: /about/i
  equal result.length, 2

  result = a.query $or:
    comments:
      $elemMatch:
        text: /really/
  equal result.length, 1

  result = b.query
    foo:
      $elemMatch:
        shape:"square"
        color:"purple"

  equal result.length, 1
  #equal result[0].get("foo")[0].shape, "square"
  #equal result[0].get("foo")[0].color, "purple"
  #equal result[0].get("foo")[0].thick, false







