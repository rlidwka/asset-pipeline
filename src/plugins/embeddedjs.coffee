module.exports =
	source: 'ejs'
	compile: (code, options, callback) ->
		ejs = require 'ejs'
		try
			callback(null, ejs.render(code))
		catch err
			callback(err)
