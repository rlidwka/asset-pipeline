module.exports =
	source: 'ejs'
	compile: (code, options, callback) ->
		try
			ejs = require 'ejs'
			inlines = require '../inlines'
			console.log(inlines.list)
			code = code.toString('utf8')
			code = ejs.render(code, inlines.prepare(options))
			inlines.call(code, (err, newcode) ->
				callback(err, newcode)
			)
		catch err
			callback(err)
