
module.exports =
	source: 'coffee'
	target: 'js'
	compile: (code, options, callback) ->
		try
			coffee = require('../require')([
				'coffee-script'
				'iced-coffee-script'
			], options)
			
			plugin_config = {
				filename: options.filename
			}
			if options.plugin_config?
				for key,val of options.plugin_config
					plugin_config[key] = val

			callback(null, coffee.compile(code.toString('utf8'), plugin_config))
		catch err
			callback(err)
