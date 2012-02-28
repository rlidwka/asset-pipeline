module.exports =
	source: 'styl'
	target: 'css'
	compile: (code, options, callback) ->
		try
			stylus = require 'stylus'
			stylus.render(code, {filename: options.filename}, callback)
		catch err
			callback(err)
