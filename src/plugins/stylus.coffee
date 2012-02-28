module.exports =
	source: 'styl'
	target: 'css'
	compile: (code, options, callback) ->
		stylus = require 'stylus'
		stylus.render(code, {filename: options.filename}, callback)
