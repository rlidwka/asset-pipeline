module.exports =
	source: 'eco'
	compile: (code, options, callback) ->
		try
			eco = require 'eco'
			callback(null, eco.render(code))
		catch err
			callback(err)
