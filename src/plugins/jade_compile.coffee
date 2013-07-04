module.exports =
	source: 'jade'
	target: 'js'
	compile: (code, options, callback) ->
		try
			plugin_config = {
				filename: options.filename
				compileDebug: false
				client: true
			}
			if options.plugin_config?
				for key,val of options.plugin_config
					plugin_config[key] = val

			jade = require('../require')('jade', options)
			js = jade.compile(code, plugin_config)
			callback(null, js)
		catch err
			callback(err)
