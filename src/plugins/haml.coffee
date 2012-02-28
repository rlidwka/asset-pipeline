module.exports =
	source: 'haml'
	target: 'html'
	compile: (code, options, callback) ->
		try
			Haml = require 'haml'
			callback(null, Haml(code)())
		catch err
			callback(err)
