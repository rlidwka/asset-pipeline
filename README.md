Coffeescript and stylesheets preprocessor/compiler for Node.js/Express.

This module (as many good things in Node) is inspired by Ruby on Rails. Rails 3.1 have beautiful framework called Asset Pipeline. Main idea of this framework is applying different filters to input files based on file extension. 

For example, user requested	`file.js`. But you don't write js, you write coffeescript with some preprocessor. So, this framework looks for `file.js.coffee.pp`, pipes it to preprocessor and gets `file.js.coffee`. Than compiles it to `file.js` and so on.


# Syntax (for Express framework):

```javascript
// here's standard Express server declaration
var express = require('express')
app = express.createServer();
app.listen(80);

// configuring assets pipeline (full definition of config options see below)
app.use(require('asset-pipeline')({
	// directory with your stylesheets or client-side scripts
	assets: './assets',
	// directory for cache
	cache: cache_dir,
}))
```

# Config options

- `assets` (default: `"./assets"`) - directory where this module does search all files and dependencies
- `cache` (default: `"./cache"`) - directory where all compiled assets are served
- `extensions` (default: `[".js", ".css"]`) - if user have requested file without md5 in it, module will serve to user only files with these extensions (TODO: i should probably describe what it is)

# Philosophy

This library writes output files to a cache and calls connect.static to serve them.
Reasons:

- in development enviroment: it's more verbose and logical. Pipeline is for compiling, Express.static for serving. You can always see what is in the cache and so on.
- in production enviroment: assets-pipeline just exports a few template functions. So, in production there will be no performance impact at all.

