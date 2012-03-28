module.exports =
	source: 'jade'
	target: 'html'
	compile: (code, options, callback) ->
		try
			jade = require 'jade'
			jade.render(code, {filename: options.filename}, callback)
		catch err
			callback(err)
