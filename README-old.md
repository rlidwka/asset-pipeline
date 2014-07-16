Assets preprocessor/compiler for Node.js/Express. It supports a lot of popular js/css compilers like `jade`, `coffeescript`, `less`, `stylus`, `ejs`, etc. and allows all these compilers to work together.

This module is inspired by Asset Pipeline (from Rails world).

Main idea of this framework is applying different filters to input files based on file extension. For example, user requested	`file.js`. But you don't write js, you write coffeescript with some preprocessor. So, this framework looks for `file.js.coffee.pp`, pipes it to preprocessor and gets `file.js.coffee`. Than compiles it to `file.js` and so on.

So typical build process looks like this:
```
                                              .- module1.coffee
file-cLee7vJT.js <-- file.js <-- file.js.ejs {-- module2.coffee                             .- template1.js.jade
                                              `- templates.coffee <-- templates.coffee.ejs {-- template2.js.jade
                                                                                            `- template3.js.jade
                                                 .- module1.less
file-USzt9bQs.css <-- file.css <-- file.css.ejs {-- module2.styl         .- image1.png
                                                 `- backgrounds.css.ejs {-- image2.png
                                                                         `- image3.png
```

It means that you have a whole bunch of different files in your project, and this module can combine them together in any way you want.

Module builds a file when user requests it first time, and then tracks all its dependencies to see if anything is changed. So first request is usually slow, but other requests should be as fast as requests to static files.

# Usage examples

See tests application, I hope it can give some ideas how it can be used.

# Command-line interface

```bash
$ echo 'test = -> console.log(<%=1+1%>)' > test.js.coffee.ejs

$ asset-pipeline test.js.coffee.ejs
test = -> console.log(<%=1+1%>)

$ asset-pipeline test.js.coffee
test = -> console.log(2)

$ asset-pipeline test.js
(function() {
  var test;

  test = function() {
    return console.log(2);
  };

}).call(this);
```

# Syntax (for Express framework):

```javascript
// here's standard Express server declaration
var express = require('express')
app = express.createServer();
app.listen(80);

// configuring assets pipeline (full definition of config options see below)
app.use(require('asset-pipeline')({
	// reference to a server itself (used in views rendering)
	server: app,
	// directory with your stylesheets or client-side scripts
	assets: './assets',
	// directory for cache
	cache: './cache',
}))
```

# Config options

- `assets` (default: `"./assets"`) - path to your assets (directory where this module does search all files and dependencies)
- `cache` (default: `"./cache"`) - path to a cache (you should create an empty directory where all compiled assets will be prepared and served)
- `extensions` (default: `[".js", ".css"]`) - if user have requested file without md5 in it, module will serve to user only files with these extensions (see below)
- `files` (default: []) - a list of additional files you want to serve (see below)
- `min_check_time` (default: 1000) - time in milliseconds, module won't check any file for updates faster than specified here (set a small value for development but large on production)
- `debug` - print to stdout some additional debug info

# Supported plugins

## Embedded javascript (EJS)

It is a template engine. I put it first because I use it almost everywhere as a clue between files.

This plugin can transform `FILE.ejs` to `FILE`. You need to have `ejs` module installed.

For example, if I want to have a coffeescript file `file.coffee` with compiled jade template located in `template.jade` in it, I will write a file `file.coffee.ejs` with something like that:

```coffeescript
# build a template function
`var template = <%-asset_include('template.js') %>;`

# use template function somehow
$('.data').first().after(template(users: args))
```

## Coffeescript

Coffeescript language compiler. It's used often to compile client-side javascript out of coffeescript sources.

This plugin can transform `FILE.coffee` to `FILE` or `FILE.js`. You need to have `coffee-script` or `iced-coffee-script` installed.

## Iced Coffeescript

Iced Coffeescript compiler.

This plugin can transform `FILE.iced` to `FILE` or `FILE.js`. You need to have `iced-coffee-script` module installed.

## Embedded coffeescript (ECO)

Embedded coffeescript. Honestly, I didn't find this plugin useful.

This plugin will transform `FILE.eco` to `FILE`. You need to have `eco` module installed.

## Less CSS

CSS preprocessor.

This plugin will transform `FILE.less` to `FILE` or `FILE.css`. You need to have `less` module installed.

## Stylus

CSS preprocessor.

This plugin will transform `FILE.styl` to `FILE` or `FILE.css`. You need to have `stylus` module installed.

## Jade compiler

Jade compiler. This plugin is used to build a compiled template (a javascript function) out of jade template.

This plugin can transform `FILE.jade` to `FILE` or `FILE.js`. You need to have `jade` module installed.

## Jade renderer

Jade compiler. This plugin is used to render a html page out of jade template.

This plugin can transform `FILE.jade` to `FILE` or `FILE.html`. You need to have `jade` module installed.

## Haml

HAML language. I use Jade instead of it, but maybe it'll be useful for someone.

This plugin will transform `FILE.haml` to `FILE` or `FILE.html`. You need to have `haml` module installed.

## Markdown

Markdown language. Can be used to build up a HTML page.

This plugin will transform `FILE.md` to `FILE` or `FILE.html`. You need to have `node-markdown` module installed. I know there is a lot of markdown modules, so ask me if you want to use another one.

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

If your compiler does not support including other files, your plugin will be nice and simple. If it does and you want to track all dependencies, just write an issue and ask for help (because of some really dark magic starting here).

# Philosophy

This library writes output files to a cache and calls connect.static to serve them.
Reasons:

- in development enviroment: it's more verbose and logical. Pipeline is for compiling, Express.static for serving. You can always see what is in the cache and so on.
- in production enviroment: assets-pipeline just exports a few template functions. So, in production there will be no performance impact.

