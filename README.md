Coffeescript and stylesheets preprocessor/compiler for Node.js/Express.

This module (as many good things in Node) is inspired by Ruby on Rails. Rails 3.1 have beautiful framework called Asset Pipeline. Main idea of this framework is applying different filters to input files based on file extension. 

For example, user requested	`file.js`, but you don't write js. You write coffeescript with some preprocessor. So, this framework looks for `file.js.coffee.pp`, pipes it to preprocessor and gets `file.js.coffee`. Than compiles it to `file.js` and so on.


Syntax (for Express framework):

```javascript
// here's standard Express server declaration
var express = require('express')
app = express.createServer();
app.listen(80);

// directory with your stylesheets or client-side scripts
var assets_dir = './assets';

// directory for cache
var cache_dir = './cache';

// middleware definitions
app.configure(function() {
	app.use(require('assets-pipeline')({assets: assets_dir, cache: cache_dir}))
	app.use(express.static(cache_dir, { maxAge: 365*24*60*60 }))
})
```

My library DOES NOT serve files to a client. It just compiles it and writes to cache. Express are serving these files itself.

Reasons:
- in development enviroment: it's more verbose and logical. Pipeline is for compiling, Express.static for serving. You can always see what is in the cache and so on.
- in production enviroment: assets-pipeline just exports a few template functions. So, in production there will be no performance impact at all.

