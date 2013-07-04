module.exports =
	source: 'haml'
	target: 'html'
	compile: (code, options, callback) ->
		try
			Haml = require('../require')('haml', options)
			callback(null, Haml(code.toString('utf8'))())
		catch err
			callback(err)
