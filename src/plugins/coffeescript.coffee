module.exports =
	source: 'coffee'
	target: 'js'
	compile: (code, options, callback) ->
		try
			coffee = require 'coffee-script'
			callback(null, coffee.compile(code, {filename: options.filename}))
		catch err
			callback(err)
