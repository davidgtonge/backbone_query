backbone-query
===================

Adds the ability to search for models with a query api similar to
[MongoDB](http://www.mongodb.org/display/DOCS/Advanced+Queries)
This is quite a new project and Pull requests are welcome!

Usage
=====

To install, include the `js/backbone-query.js` file in your HTML page, after Backbone and it's dependencies.

Then extend your collections from Backbone.QueryCollection rather than from Backbone.Collection.
Your collections will now have a `query` method that can be used like this:

```js
MyCollection.query({ {featured:true}, {likes: $gt:10} )};
// Returns all models where the featured attribute is true and there are
// more than 10 likes

MyCollection.query(
    {tags: { $any: ["coffeescript", "backbone", "mvc"]}},
    {sortBy: "likes", order: "desc", limit:10, page:2}
);
// Finds models that have either "coffeescript", "backbone", "mvc" in their "tags" attribute
// Sorts these models by the "likes" attribute in descending order
// Returns only 10 models, starting from the 11th model (page 2)

MyCollection.query({
  // Models must match all these queries
  $and:{
    title: {$like: "news"}, // Title attribute contains the string "news"
    likes: {$gt: 10}}, // Likes attribute is greater than 10

  // Models must match one of these queries
  $or:{
    featured: true, // Featured attribute is true
    category:{$in:["code","programming","javascript"]}}
    //Category attribute is either "code", "programming", or "javascript"
});
```

Query API
===

### $equal
Performs a strict equality test using `===`. If no operator is provided and the query value isn't a regex then `$equal` is assumed.

```javascript
MyCollection.query({ title:"Test" });
// Returns all models which have a "title" attribute of "Test"

MyCollection.query({ title: {$equal:"Test"} }); // Same as above
```

### $contains
Assumes that the model property is an array and searches for the query value in the array

```js
MyCollection.query({ colors: {$contains: "red"} });
// Returns models which contain the value "red" in a "colors" attribute that is an array.
// e.g. a model with this attribute colors:["red","yellow","blue"] would be returned
```

### $ne
"Not equal", the opposite of $equal, returns all models which don't have the query value

```js
MyCollection.query({ title: {$ne:"Test"} });
// Returns all models which don't have a "title" attribute of "Test"
```

### $lt, $lte, $gt, $gte
These conditional operators can be used for greater than and less than comparisons in queries

```js
MyCollection.query({ likes: {$lt:10} });
// Returns all models which have a "likes" attribute of less than 10
MyCollection.query({ likes: {$lte:10} });
// Returns all models which have a "likes" attribute of less than or equal to 10
MyCollection.query({ likes: {$gt:10} });
// Returns all models which have a "likes" attribute of greater than 10
MyCollection.query({ likes: {$gte:10} });
// Returns all models which have a "likes" attribute of greater than or equal to 10
```

### $between
To check if a value is in-between 2 query values use the $between operator and supply an array with the min and max value

```js
MyCollection.query({ likes: {$between:[5,15} });
// Returns all models which have a "likes" attribute of greater than 5 and less then 15
```

### $in
An array of possible values can be supplied using $in, a model will be returned if any of the supplied values is matched

```js
MyCollection.query({ title: {$in:["About", "Home", "Contact"] } });
// Returns all models which have a title attribute of either "About", "Home", or "Contact"
```

### $nin
"Not in", the opposite of $in. A model will be returned if none of the supplied values is matched

```js
MyCollection.query({ title: {$nin:["About", "Home", "Contact"] } });
// Returns all models which don't have a title attribute of either
// "About", "Home", or "Contact"
```

### $all
Assumes the model property is an array and only returns models where all supplied values are matched.

```js
MyCollection.query({ colors: {$all:["red", "yellow"] } });
// Returns all models which have "red" and "yellow" in their colors attribute.
// A model with the attribute colors:["red","yellow","blue"] would be returned
// But a model with the attribute colors:["red","blue"] would not be returned
```

### $any
Assumes the model property is an array and returns models where any of the supplied values are matched.

```js
MyCollection.query({ colors: {$any:["red", "yellow"] } });
// Returns models which have either "red" or "yellow" in their colors attribute.
```

### $size
Assumes the model property is an array and only returns models the model property's length matches the supplied values

```js
MyCollection.query({ colors: {$size:2 } });
// Returns all models which 2 values in the colors attribute
```

### $exists or $has
Checks for the existence of an attribute. Can be supplied either true or false.

```js
MyCollection.query({ title: {$exists: true } });
// Returns all models which have a "title" attribute
MyCollection.query({ title: {$has: false } });
// Returns all models which don't have a "title" attribute
```

### $like
Assumes the model attribute is a string and checks if the supplied query value is a substring of the property.
Uses indexOf rather than regex for performance reasons

```js
MyCollection.query({ title: {$like: "Test" } });
//Returns all models which have a "title" attribute what
//contains the string "Test", e.g. "Testing", "Tests", "Test", etc.
```

### $regex
Checks if the model attribute matches the supplied regular expression. The regex query can be supplied without the `$regex` keyword

```js
MyCollection.query({ content: {$regex: /coffeescript/gi } });
// Checks for a regex match in the content attribute
MyCollection.query({ content: /coffeescript/gi });
// Same as above
```

### $cb
A callback function can be supplied as a test. The callback will receive the attribute and should return either true or false

```js
MyCollection.query({ title: {$cb: function(attr){ return attr.charAt(0) === "c";}} });
// Returns all models that have a title attribute that starts with "c"
```

Combined Queries
================

Multiple queries can be combined together. By default all supplied queries must be matched `$and`. However it is possible
to specify either `$or`, `$nor`, `$not` to implement alternate logic.

### $and

```js
MyCollection.query({ $and: { title: {$like: "News"}, likes: {$gt: 10}}});
// Returns all models that contain "News" in the title and have more than 10 likes.
MyCollection.query({ title: {$like: "News"}, likes: {$gt: 10} });
// Same as above as $and is assumed if not supplied
```

### $or

```js
MyCollection.query({ $or: { title: {$like: "News"}, likes: {$gt: 10}}});
// Returns all models that contain "News" in the title OR have more than 10 likes.
```

### $nor
The opposite of `$or`

```js
MyCollection.query({ $nor: { title: {$like: "News"}, likes: {$gt: 10}}});
// Returns all models that don't contain "News" in the title NOR have more than 10 likes.
```

### $not
The opposite of `$and`

```js
MyCollection.query({ $not: { title: {$like: "News"}, likes: {$gt: 10}}});
// Returns all models that don't contain "News" in the title AND DON'T have more than 10 likes.
```

Compound Queries
================

It is possible to use multiple combined queries, for example searching for models that have a specific title attribute,
and either a category of "abc" or a tag of "xyz"

```js
MyCollection.query({
    $and: { title: {$like: "News"}},
    $or: {likes: {$gt: 10}, color:{$contains:"red"}}
});
//Returns models that have "News" in their title and
//either have more than 10 likes or contain the color red.
```

Sorting
=======
Optional `sortBy` and `order` attributes can be supplied as part of an options object.
`sortBy` can either be a model key or a callback function which will be called with each model in the array.

```js
MyCollection.query({title: {$like: "News"}}, {sortBy: "likes"});
// Returns all models that contain "News" in the title,
// sorted according to their "likes" attribute (ascending)

MyCollection.query({title: {$like: "News"}}, {sortBy: "likes", order:"desc"});
// Same as above, but "descending"
MyCollection.query(
    {title: {$like: "News"}},
    {sortBy: function(model){ return model.get("title").charAt(1);}}
);
// Results sorted according to 2nd character of the title attribute
```


Paging
======
To return only a subset of the results paging properties can be supplied as part of an options object.
A `limit` property must be supplied and optionally a `offset` or a `page` property can be supplied.

```js
MyCollection.query({likes:{$gt:10}}, {limit:10});
// Returns the first 10 models that have more than 10 likes

MyCollection.query({likes:{$gt:10}}, {limit:10, offset:5});
// Returns 10 models that have more than 10 likes starting
//at the 6th model in the results

MyCollection.query({likes:{$gt:10}}, {limit:10, page:2});
// Returns 10 models that have more than 10 likes starting
//at the 11th model in the results (page 2)
```

Still Todo
=========
* More comprehensive tests
* Add date comparators (check if dates can be used as is with $lt, $gt, $between)


Author
======

Dave Tonge - [davidgtonge](http://github.com/davidgtonge)
