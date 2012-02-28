module.exports =
	source: 'coffee'
	target: 'js'
	compile: (code, options, callback) ->
		coffee = require 'coffee-script'
		try
			callback(null, coffee.compile(code, {filename: options.filename}))
		catch err
			callback(err)
