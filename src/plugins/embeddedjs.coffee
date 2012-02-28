module.exports =
	source: 'ejs'
	compile: (code, options, callback) ->
		try
			ejs = require 'ejs'
			callback(null, ejs.render(code))
		catch err
			callback(err)
