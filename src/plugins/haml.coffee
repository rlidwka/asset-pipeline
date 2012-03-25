module.exports =
	source: 'haml'
	target: 'html'
	compile: (code, options, callback) ->
		try
			Haml = require 'haml'
			callback(null, Haml(code.toString('utf8'))())
		catch err
			callback(err)
