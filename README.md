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
	// reference to a server (used in views rendering)
	server: app,
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
- `debug` - print to stdout some additional debug info

# Writing custom plugin

If you have some compiler you want to use, and it is not (yet?) supported by assets-pipeline, you can just write your own module and copy it to plugins directory.

Your module should export object simular to that (you can look inside existing plugins):

```javascript
module.exports = {
  // file extension (or array of these extensions) of files 
  // that will be processed by your plugin, mandatory
  source: 'coffee',

  // file extension (or array of these extensions) of target files, optional
  target: 'js',

  // your compiler, arguments: source code, some options 
  // (options.filename is quite useful) and a callback(err, compiled_code)
  compile: function(code, options, callback) {
    callback(null, require('coffee-script').compile(code));
  }
};
```

If your compiler does not support including other files, your plugin will be nice and simple. If it does and you want to track all dependencies, just write an issue and ask for help (because of some really black magic starting here).

# Philosophy

This library writes output files to a cache and calls connect.static to serve them.
Reasons:

- in development enviroment: it's more verbose and logical. Pipeline is for compiling, Express.static for serving. You can always see what is in the cache and so on.
- in production enviroment: assets-pipeline just exports a few template functions. So, in production there will be no performance impact at all.

