module.exports =
	source: 'jade'
	target: 'js'
	compile: (code, options, callback) ->
		try
			jade = require 'jade'
			js = jade.compile(code, {
				filename: options.filename
				compileDebug: false
				client: true
			})
			callback(null, js)
		catch err
			callback(err)
