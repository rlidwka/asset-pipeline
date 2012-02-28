coffee = require 'coffee-script'
module.exports =
	source: 'coffee'
	target: 'js'
	compiler: (code, callback) ->
		try
			callback(null, coffee.compile(code))
		catch err
			callback(err)
