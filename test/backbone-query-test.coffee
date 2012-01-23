module "Backbone Query"

create = ->
  new Backbone.QueryCollection [
    {title:"Home", colors:["red","yellow","blue"], likes:12, featured:true, content: "Dummy content about coffeescript"}
    {title:"About", colors:["red"], likes:2, featured:true, content: "dummy content about javascript"}
    {title:"Contact", colors:["red","blue"], likes:20, content: "Dummy content about PHP"}
  ]

test "Simple equals query", ->
  a = create()
  result = a.query title:"Home"
  equal result.length, 1
  equal result[0].get("title"), "Home"

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

test "$in operator", ->
  a = create()
  result = a.query title: {$in: ["Home","About"]}
  equal result.length, 2

test "$nin operator", ->
  a = create()
  result = a.query title: {$nin: ["Home","About"]}
  equal result.length, 1
  equal result[0].get("title"), "Contact"

test "$all operator", ->
  a = create()
  result = a.query colors: {$all: ["red","blue"]}
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

# TODO: Need regex tests

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









