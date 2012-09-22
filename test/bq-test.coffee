# Requires
assert = require('assert')
{QueryCollection} = require "../src/backbone-query"
Backbone = require('backbone')

create = ->
  new QueryCollection [
    {title:"Home", colors:["red","yellow","blue"], likes:12, featured:true, content: "Dummy content about coffeescript"}
    {title:"About", colors:["red"], likes:2, featured:true, content: "dummy content about javascript"}
    {title:"Contact", colors:["red","blue"], likes:20, content: "Dummy content about PHP"}
  ]





describe "Backbone Query Tests", ->

  it "Equals query", ->
    a = create()
    result = a.query title:"Home"
    assert.equal result.length, 1
    assert.equal result[0].get("title"), "Home"
  
    result = a.whereBy colors: "blue"
    assert.equal result.length, 2
  
    result = a.whereBy colors: ["red", "blue"]
    assert.equal result.length, 1

  it "Simple equals query (no results)", ->
    a = create()
    result = a.whereBy title:"Homes"
    assert.equal result.length, 0
  
  it "Simple equals query with explicit $equal", ->
    a = create()
    result = a.whereBy title: {$equal: "About"}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "About"
  
  it "$contains operator", ->
    a = create()
    result = a.whereBy colors: {$contains: "blue"}
    assert.equal result.length, 2
  
  it "$ne operator", ->
    a = create()
    result = a.whereBy title: {$ne: "Home"}
    assert.equal result.length, 2
  
  it "$lt operator", ->
    a = create()
    result = a.whereBy likes: {$lt: 12}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "About"
  
  it "$lte operator", ->
    a = create()
    result = a.whereBy likes: {$lte: 12}
    assert.equal result.length, 2
  
  it "$gt operator", ->
    a = create()
    result = a.whereBy likes: {$gt: 12}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "Contact"
  
  it "$gte operator", ->
    a = create()
    result = a.whereBy likes: {$gte: 12}
    assert.equal result.length, 2
  
  it "$between operator", ->
    a = create()
    result = a.whereBy likes: {$between: [1,5]}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "About"
  
  it "$in operator", ->
    a = create()
    result = a.whereBy title: {$in: ["Home","About"]}
    assert.equal result.length, 2
  
  it "$in operator with wrong query value", ->
    a = create()
    result = a.whereBy title: {$in: "Home"}
    assert.equal result.length, 0
  
  it "$nin operator", ->
    a = create()
    result = a.whereBy title: {$nin: ["Home","About"]}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "Contact"
  
  it "$all operator", ->
    a = create()
    result = a.whereBy colors: {$all: ["red","blue"]}
    assert.equal result.length, 2
  
  it "$all operator (wrong values)", ->
    a = create()
    result = a.whereBy title: {$all: ["red","blue"]}
    assert.equal result.length, 0
  
    result = a.whereBy colors: {$all: "red"}
    assert.equal result.length, 0
  
  it "$any operator", ->
    a = create()
    result = a.whereBy colors: {$any: ["red","blue"]}
    assert.equal result.length, 3
  
    result = a.whereBy colors: {$any: ["yellow","blue"]}
    assert.equal result.length, 2
  
  it "$size operator", ->
    a = create()
    result = a.whereBy colors: {$size: 3}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "Home"
  
  it "$exists operator", ->
    a = create()
    result = a.whereBy featured: {$exists: true}
    assert.equal result.length, 2
  
  it "$has operator", ->
    a = create()
    result = a.whereBy featured: {$exists: false}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "Contact"
  
  it "$like operator", ->
    a = create()
    result = a.whereBy content: {$like: "javascript"}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "About"
  
  it "$like operator 2", ->
    a = create()
    result = a.whereBy content: {$like: "content"}
    assert.equal result.length, 3
  
  it "$likeI operator", ->
    a = create()
    result = a.whereBy content: {$likeI: "dummy"}
    assert.equal result.length, 3
    result = a.whereBy content: {$like: "dummy"}
    assert.equal result.length, 1
  
  it "$regex", ->
    a = create()
    result = a.whereBy content: {$regex: /javascript/gi}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "About"
  
  it "$regex2", ->
    a = create()
    result = a.whereBy content: {$regex: /dummy/}
    assert.equal result.length, 1
  
  it "$regex3", ->
    a = create()
    result = a.whereBy content: {$regex: /dummy/i}
    assert.equal result.length, 3
  
  it "$regex4", ->
    a = create()
    result = a.whereBy content: /javascript/i
    assert.equal result.length, 1
  
  it "$cb - callback", ->
    a = create()
    result = a.whereBy title: {$cb: (attr) -> attr.charAt(0).toLowerCase() is "c"}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "Contact"
  
  it "$cb - callback - checking 'this' is the model", ->
    a = create()
    result = a.whereBy title:
      $cb: (attr) -> @get("title") is "Home"
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "Home"
  
  it "$and operator", ->
    a = create()
    result = a.whereBy likes: {$gt: 5}, colors: {$contains: "yellow"}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "Home"
  
  it "$and operator (explicit)", ->
    a = create()
    result = a.whereBy $and: {likes: {$gt: 5}, colors: {$contains: "yellow"}}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "Home"
  
  it "$or operator", ->
    a = create()
    result = a.whereBy $or: {likes: {$gt: 5}, colors: {$contains: "yellow"}}
    assert.equal result.length, 2
  
  it "$or2 operator", ->
    a = create()
    result = a.whereBy $or: {likes: {$gt: 5}, featured: true}
    assert.equal result.length, 3
  
  it "$nor operator", ->
    a = create()
    result = a.whereBy $nor: {likes: {$gt: 5}, colors: {$contains: "yellow"}}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "About"
  
  it "Compound Queries", ->
    a = create()
    result = a.whereBy $and: {likes: {$gt: 5}}, $or: {content: {$like: "PHP"},  colors: {$contains: "yellow"}}
    assert.equal result.length, 2
  
    result = a.whereBy
      $and:
        likes: $lt: 15
      $or:
        content:
          $like: "Dummy"
        featured:
          $exists:true
      $not:
        colors: $contains: "yellow"
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "About"
  
  

  it "Limit", ->
    a = create()
    result = a.whereBy {likes: {$gt: 1}}, {limit:2}
    assert.equal result.length, 2
  
  it "Offset", ->
    a = create()
    result = a.whereBy {likes: {$gt: 1}}, {limit:2, offset:2}
    assert.equal result.length, 1
  
  it "Page", ->
    a = create()
    result = a.whereBy {likes: {$gt: 1}}, {limit:3, page:2}
    assert.equal result.length, 0
  
  it "Sorder by model key", ->
    a = create()
    result = a.query {likes: {$gt: 1}}, {sortBy:"likes"}
    assert.equal result.length, 3
    assert.equal result[0].get("title"), "About"
    assert.equal result[1].get("title"), "Home"
    assert.equal result[2].get("title"), "Contact"
  
  it "Sorder by model key with descending order", ->
    a = create()
    result = a.query {likes: {$gt: 1}}, {sortBy:"likes", order:"desc"}
    assert.equal result.length, 3
    assert.equal result[2].get("title"), "About"
    assert.equal result[1].get("title"), "Home"
    assert.equal result[0].get("title"), "Contact"
  
  it "Sorder by function", ->
    a = create()
    result = a.query {likes: {$gt: 1}}, {sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal result.length, 3
    assert.equal result[2].get("title"), "About"
    assert.equal result[0].get("title"), "Home"
    assert.equal result[1].get("title"), "Contact"
  
  it "cache", ->
    a = create()
    result = a.whereBy {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal result.length, 3
    result = a.whereBy {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal result.length, 3
    a.remove result.at(0)
    result = a.whereBy {likes: {$gt: 1}}, {sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal result.length, 2
    result = a.whereBy {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal result.length, 3


  it "cache with multiple collections", ->
    a = create()
    b = create()
    b.remove b.at(0)
    assert.equal b.length, 2
    assert.equal a.length, 3


    a_result = a.query {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal a_result.length, 3
    b_result = b.query {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal b_result.length, 2

    a.remove a_result[0]
    b.remove b_result[0]
  
    a_result = a.query {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal a_result.length, 3
    assert.equal a.length, 2


    b_result = b.query {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal b_result.length, 2
    assert.equal b.length, 1

    a.resetQueryCache()
    a_result = a.query {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal a_result.length, 2
    assert.equal a.length, 2
  
    b_result = b.query {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal b_result.length, 2
    assert.equal b.length, 1


  it "null attribute with various operators", ->
    a = create()
    result = a.whereBy wrong_key: {$like: "test"}
    assert.equal result.length, 0
    result = a.whereBy wrong_key: {$regex: /test/}
    assert.equal result.length, 0
    result = a.whereBy wrong_key: {$contains: "test"}
    assert.equal result.length, 0
    result = a.whereBy wrong_key: {$all: [12,23]}
    assert.equal result.length, 0
    result = a.whereBy wrong_key: {$any: [12,23]}
    assert.equal result.length, 0
    result = a.whereBy wrong_key: {$size: 10}
    assert.equal result.length, 0
    result = a.whereBy wrong_key: {$in: [12,23]}
    assert.equal result.length, 0
    result = a.whereBy wrong_key: {$nin: [12,23]}
    assert.equal result.length, 0
  
  it "Where method", ->
    a = create()
    result = a.whereBy likes: $gt: 5
    assert.equal result.length, 2
    assert.equal result.models.length, result.length
  

  it "$computed", ->
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
  
    assert.equal result.length, 1
    assert.equal result[0].get("first_name"), "Dave"
  
    result = c.query
      full_name: $computed: $likeI: "n sm"
    assert.equal result.length, 1
    assert.equal result[0].get("first_name"), "John"

  
  it "$elemMatch", ->
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
    assert.equal result.length, 2
  
    result = a.query $or:
      comments:
        $elemMatch:
          text: /post/
    assert.equal result.length, 1
  
    result = a.query $or:
      comments:
        $elemMatch:
          text: /post/
      title: /about/i
    assert.equal result.length, 2
  
    result = a.query $or:
      comments:
        $elemMatch:
          text: /really/
    assert.equal result.length, 1
  
    result = b.query
      foo:
        $elemMatch:
          shape:"square"
          color:"purple"
  
    assert.equal result.length, 1
    assert.equal result[0].get("foo")[0].shape, "square"
    assert.equal result[0].get("foo")[0].color, "purple"
    assert.equal result[0].get("foo")[0].thick, false


  it "$any and $all", ->
    a = name: "test", tags1: ["red","yellow"], tags2: ["orange", "green", "red", "blue"]
    b = name: "test1", tags1: ["purple","blue"], tags2: ["orange", "red", "blue"]
    c = name: "test2", tags1: ["black","yellow"], tags2: ["green", "orange", "blue"]
    d = name: "test3", tags1: ["red","yellow","blue"], tags2: ["green"]
    e = new QueryCollection [a,b,c,d]
  
    result = e.query
      tags1: $any: ["red","purple"] # should match a, b, d
      tags2: $all: ["orange","green"] # should match a, c
  
    assert.equal result.length, 1
    assert.equal result[0].get("name"), "test"

  it "$elemMatch - compound queries", ->
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

    result = a.query
      comments:
        $elemMatch:
          $not:
            text:/page/

    assert.equal result.length, 1


  # Test from RobW - https://github.com/Rob--W
  it "Explicit $and combined with matching $or must return the correct number of items", ->
    Col = new QueryCollection [
      {equ:'ok', same: 'ok'},
      {equ:'ok', same: 'ok'}
    ]
    result = Col.query
      $and:
        equ: 'ok'         # Matches both items
        $or:
          same: 'ok'      # Matches both items
    assert.equal result.length, 2

  # Test from RobW - https://github.com/Rob--W
  it "Implicit $and consisting of non-matching subquery and $or must return empty list", ->
    Col = new QueryCollection [
      {equ:'ok', same: 'ok'},
      {equ:'ok', same: 'ok'}
    ]
    result = Col.query
      equ: 'bogus'        # Matches nothing
      $or:
        same: 'ok'        # Matches all items, but due to implicit $and, this subquery should not affect the result
    assert.equal result.length, 0

  it "Testing nested compound operators", ->
    a = create()
    result = a.whereBy
      $and:
        colors: $contains: "blue" # Matches 1,3
        $or:
          featured:true # Matches 1,2
          likes:12 # Matches 1
      # And only matches 1

      $or:[
        {content:$like:"dummy"} # Matches 2
        {content:$like:"Dummy"} # Matches 1,3
      ]
    # Or matches 3
    assert.equal result.length, 1

    result = a.whereBy
      $and:
        colors: $contains: "blue" # Matches 1,3
        $or:
          featured:true # Matches 1,2
          likes:20 # Matches 3
      # And only matches 2

      $or:[
        {content:$like:"dummy"} # Matches 2
        {content:$like:"Dummy"} # Matches 1,3
      ]
    # Or matches 3
    assert.equal result.length, 2

  it "works with queries supplied as arrays", ->
    a = create()
    result = a.query
      $or: [
        {title:"Home"}
        {title:"About"}
      ]
    assert.equal result.length, 2
    assert.equal result[0].get("title"), "Home"
    assert.equal result[1].get("title"), "About"
  
