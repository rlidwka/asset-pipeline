module.exports =
	source: 'eco'
	compile: (code, options, callback) ->
		try
			eco = require('../require')('eco', options)
			callback(null, eco.render(code))
		catch err
			callback(err)
