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
			
			plugin_config = {
				filename: options.filename
			}
			if options.plugin_config?
				for key,val of options.plugin_config
					plugin_config[key] = val

			callback(null, coffee.compile(code.toString('utf8'), plugin_config))
		catch err
			callback(err)
