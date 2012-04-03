module.exports =
	source: 'eco'
	compile: (code, options, callback) ->
		try
			eco = require 'eco'
			inlines = require '../inlines'
			code = eco.render(code, inlines.prepare(options))
			inlines.call(code, (err, newcode) ->
				callback(err, newcode)
			)
		catch err
			callback(err)
