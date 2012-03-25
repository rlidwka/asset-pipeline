try_require = (mod) ->
	try
		result = require mod
	catch err
		result = null
	result

module.exports =
	source: 'coffee'
	target: 'js'
	compile: (code, options, callback) ->
		try
			coffee = null
			unless coffee?
				coffee = try_require 'coffee-script'
			unless coffee?
				coffee = try_require 'iced-coffee-script'
			unless coffee?
				throw new Error('could not find any coffee')
			callback(null, coffee.compile(code.toString('utf8'), {filename: options.filename}))
		catch err
			callback(err)
