module.exports =
	source: 'iced'
	target: 'js'
	compile: (code, options, callback) ->
		try
			coffee = require 'iced-coffee-script'
			callback(null, coffee.compile(code, {filename: options.filename}))
		catch err
			callback(err)
