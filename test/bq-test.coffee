# Requires
assert = require('assert')
{QueryCollection} = require "../src/backbone-query"
Backbone = require('backbone')

QueryCollection::findAll = QueryCollection::where_by

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
  
    #result = a.findAll colors: "blue"
    #assert.equal result.length, 2
  
    #result = a.findAll colors: ["red", "blue"]
    #assert.equal result.length, 1
  
  
  
  it "Simple equals query (no results)", ->
    a = create()
    result = a.findAll title:"Homes"
    assert.equal result.length, 0
  
  it "Simple equals query with explicit $equal", ->
    a = create()
    result = a.findAll title: {$equal: "About"}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "About"
  
  it "$contains operator", ->
    a = create()
    result = a.findAll colors: {$contains: "blue"}
    assert.equal result.length, 2
  
  it "$ne operator", ->
    a = create()
    result = a.findAll title: {$ne: "Home"}
    assert.equal result.length, 2
  
  it "$lt operator", ->
    a = create()
    result = a.findAll likes: {$lt: 12}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "About"
  
  it "$lte operator", ->
    a = create()
    result = a.findAll likes: {$lte: 12}
    assert.equal result.length, 2
  
  it "$gt operator", ->
    a = create()
    result = a.findAll likes: {$gt: 12}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "Contact"
  
  it "$gte operator", ->
    a = create()
    result = a.findAll likes: {$gte: 12}
    assert.equal result.length, 2
  
  it "$between operator", ->
    a = create()
    result = a.findAll likes: {$between: [1,5]}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "About"
  
  it "$in operator", ->
    a = create()
    result = a.findAll title: {$in: ["Home","About"]}
    assert.equal result.length, 2
  
  it "$in operator with wrong query value", ->
    a = create()
    result = a.findAll title: {$in: "Home"}
    assert.equal result.length, 0
  
  it "$nin operator", ->
    a = create()
    result = a.findAll title: {$nin: ["Home","About"]}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "Contact"
  
  it "$all operator", ->
    a = create()
    result = a.findAll colors: {$all: ["red","blue"]}
    assert.equal result.length, 2
  
  it "$all operator (wrong values)", ->
    a = create()
    result = a.findAll title: {$all: ["red","blue"]}
    assert.equal result.length, 0
  
    result = a.findAll colors: {$all: "red"}
    assert.equal result.length, 0
  
  it "$any operator", ->
    a = create()
    result = a.findAll colors: {$any: ["red","blue"]}
    assert.equal result.length, 3
  
    result = a.findAll colors: {$any: ["yellow","blue"]}
    assert.equal result.length, 2
  
  it "$size operator", ->
    a = create()
    result = a.findAll colors: {$size: 3}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "Home"
  
  it "$exists operator", ->
    a = create()
    result = a.findAll featured: {$exists: true}
    assert.equal result.length, 2
  
  it "$has operator", ->
    a = create()
    result = a.findAll featured: {$exists: false}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "Contact"
  
  it "$like operator", ->
    a = create()
    result = a.findAll content: {$like: "javascript"}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "About"
  
  it "$like operator 2", ->
    a = create()
    result = a.findAll content: {$like: "content"}
    assert.equal result.length, 3
  
  it "$likeI operator", ->
    a = create()
    result = a.findAll content: {$likeI: "dummy"}
    assert.equal result.length, 3
    result = a.findAll content: {$like: "dummy"}
    assert.equal result.length, 1
  
  it "$regex", ->
    a = create()
    result = a.findAll content: {$regex: /javascript/gi}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "About"
  
  it "$regex2", ->
    a = create()
    result = a.findAll content: {$regex: /dummy/}
    assert.equal result.length, 1
  
  it "$regex3", ->
    a = create()
    result = a.findAll content: {$regex: /dummy/i}
    assert.equal result.length, 3
  
  it "$regex4", ->
    a = create()
    result = a.findAll content: /javascript/i
    assert.equal result.length, 1
  
  it "$cb - callback", ->
    a = create()
    result = a.findAll title: {$cb: (attr) -> attr.charAt(0).toLowerCase() is "c"}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "Contact"
  
  it "$cb - callback - checking 'this' is the model", ->
    a = create()
    result = a.findAll title:
      $cb: (attr) -> @get("title") is "Home"
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "Home"
  
  it "$and operator", ->
    a = create()
    result = a.findAll likes: {$gt: 5}, colors: {$contains: "yellow"}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "Home"
  
  it "$and operator (explicit)", ->
    a = create()
    result = a.findAll $and: {likes: {$gt: 5}, colors: {$contains: "yellow"}}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "Home"
  
  it "$or operator", ->
    a = create()
    result = a.findAll $or: {likes: {$gt: 5}, colors: {$contains: "yellow"}}
    assert.equal result.length, 2
  
  it "$or2 operator", ->
    a = create()
    result = a.findAll $or: {likes: {$gt: 5}, featured: true}
    assert.equal result.length, 3
  
  it "$nor operator", ->
    a = create()
    result = a.findAll $nor: {likes: {$gt: 5}, colors: {$contains: "yellow"}}
    assert.equal result.length, 1
    assert.equal result.at(0).get("title"), "About"
  
  it "Compound Queries", ->
    a = create()
    result = a.findAll $and: {likes: {$gt: 5}}, $or: {content: {$like: "PHP"},  colors: {$contains: "yellow"}}
    assert.equal result.length, 2
  
    result = a.findAll
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
    result = a.findAll {likes: {$gt: 1}}, {limit:2}
    assert.equal result.length, 2
  
  it "Offset", ->
    a = create()
    result = a.findAll {likes: {$gt: 1}}, {limit:2, offset:2}
    assert.equal result.length, 1
  
  it "Page", ->
    a = create()
    result = a.findAll {likes: {$gt: 1}}, {limit:3, page:2}
    assert.equal result.length, 0
  
  it "Sorder by model key", ->
    a = create()
    result = a.findAll {likes: {$gt: 1}}, {sortBy:"likes"}
    assert.equal result.length, 3
    #assert.equal result.at(0).get("title"), "About"
    #assert.equal result[1].get("title"), "Home"
    #assert.equal result[2].get("title"), "Contact"
  
  it "Sorder by model key with descending order", ->
    a = create()
    result = a.findAll {likes: {$gt: 1}}, {sortBy:"likes", order:"desc"}
    assert.equal result.length, 3
    #assert.equal result[2].get("title"), "About"
    #assert.equal result[1].get("title"), "Home"
    #assert.equal result.at(0).get("title"), "Contact"
  
  it "Sorder by function", ->
    a = create()
    result = a.findAll {likes: {$gt: 1}}, {sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal result.length, 3
    #assert.equal result[2].get("title"), "About"
    #assert.equal result.at(0).get("title"), "Home"
    #assert.equal result[1].get("title"), "Contact"
  
  it "cache", ->
    a = create()
    result = a.findAll {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal result.length, 3
    result = a.findAll {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal result.length, 3
    a.remove result.at(0)
    result = a.findAll {likes: {$gt: 1}}, {sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal result.length, 2
    result = a.findAll {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal result.length, 3

  ###
  it "cache with multiple collections", ->
    a = create()
    b = create()
    b.remove b.at(0)
    assert.equal b.length, 2
    assert.equal a.length, 3
  
    a_result = a.findAll {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal a_result.length, 3
    b_result = b.findAll {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal b_result.length, 2
  
    a.remove a_result[0]
    b.remove b_result[0]
  
    a_result = a.findAll {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal a_result.length, 3
    assert.equal a.length, 2
    b_result = b.findAll {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal b_result.length, 2
    assert.equal b.length, 1
  
    a.reset_query_cache()
    a_result = a.findAll {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal a_result.length, 2
    assert.equal a.length, 2
  
    b_result = b.findAll {likes: {$gt: 1}}, {cache:true, sortBy: (model) -> model.get("title").charAt(2) }
    assert.equal b_result.length, 2
    assert.equal b.length, 1
  ###

  it "null attribute with various operators", ->
    a = create()
    result = a.findAll wrong_key: {$like: "test"}
    assert.equal result.length, 0
    result = a.findAll wrong_key: {$regex: /test/}
    assert.equal result.length, 0
    result = a.findAll wrong_key: {$contains: "test"}
    assert.equal result.length, 0
    result = a.findAll wrong_key: {$all: [12,23]}
    assert.equal result.length, 0
    result = a.findAll wrong_key: {$any: [12,23]}
    assert.equal result.length, 0
    result = a.findAll wrong_key: {$size: 10}
    assert.equal result.length, 0
    result = a.findAll wrong_key: {$in: [12,23]}
    assert.equal result.length, 0
    result = a.findAll wrong_key: {$nin: [12,23]}
    assert.equal result.length, 0
  
  it "Where method", ->
    a = create()
    result = a.where_by likes: $gt: 5
    assert.equal result.length, 2
    assert.equal result.models.length, result.length
  
  ###
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
  
    result = c.findAll
      full_name: $computed: "Dave Tonge"
  
    assert.equal result.length, 1
    assert.equal result[0].get("first_name"), "Dave"
  
    result = c.findAll
      full_name: $computed: $likeI: "n sm"
    assert.equal result.length, 1
    assert.equal result[0].get("first_name"), "John"
  ###
  
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
  
    result = a.findAll $or:
      comments:
        $elemMatch:
          text: text_search
      title: text_search
    assert.equal result.length, 2
  
    result = a.findAll $or:
      comments:
        $elemMatch:
          text: /post/
    assert.equal result.length, 1
  
    result = a.findAll $or:
      comments:
        $elemMatch:
          text: /post/
      title: /about/i
    assert.equal result.length, 2
  
    result = a.findAll $or:
      comments:
        $elemMatch:
          text: /really/
    assert.equal result.length, 1
  
    result = b.findAll
      foo:
        $elemMatch:
          shape:"square"
          color:"purple"
  
    assert.equal result.length, 1
    #assert.equal result[0].get("foo")[0].shape, "square"
    #assert.equal result[0].get("foo")[0].color, "purple"
    #assert.equal result[0].get("foo")[0].thick, false

  ###
  it "$any and $all", ->
    a = name: "test", tags1: ["red","yellow"], tags2: ["orange", "green", "red", "blue"]
    b = name: "test1", tags1: ["purple","blue"], tags2: ["orange", "red", "blue"]
    c = name: "test2", tags1: ["black","yellow"], tags2: ["green", "orange", "blue"]
    d = name: "test3", tags1: ["red","yellow","blue"], tags2: ["green"]
    e = new QueryCollection [a,b,c,d]
  
    result = e.findAll
      tags1: $any: ["red","purple"] # should match a, b, d
      tags2: $all: ["orange","green"] # should match a, c
  
    assert.equal result.length, 1
    assert.equal result[0].get("name"), "test"
  ###

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
  
