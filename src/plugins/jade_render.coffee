module.exports =
	source: 'jade'
	target: 'html'
	compile: (code, options, callback) ->
		try
			jade = require('../require')('jade', options)
			# jade reads from filename in case of error, shouldn't pass fake
			#jade.render(code, {filename: options.filename}, callback)
			jade.render(code, options.plugin_config ? {}, callback)
		catch err
			callback(err)
