module.exports =
	source: 'ejs'
	compile: (code, options, callback) ->
		try
			ejs = require('../require')('ejs', options)
			inlines = require '../inlines'
			code = code.toString('utf8')
			code = ejs.render(code, inlines.prepare(options))
			inlines.call(code, (err, newcode) ->
				callback(err, newcode)
			)
		catch err
			callback(err)
