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
  equal result.length, 3

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
  equal result.length, 3

  result = a.query colors: {$all: "red"}
  equal result.length, 3

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
      content: $like: "Dummy"
      featured:$exists:true
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