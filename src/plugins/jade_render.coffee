module.exports =
	source: 'jade'
	target: 'html'
	compile: (code, options, callback) ->
		try
			jade = require 'jade'
			# jade reads from filename in case of error, shouldn't pass fake
			#jade.render(code, {filename: options.filename}, callback)
			jade.render(code, callback)
		catch err
			callback(err)
