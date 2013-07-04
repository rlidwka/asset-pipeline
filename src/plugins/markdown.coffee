module.exports =
	source: 'md'
	target: 'html'
	compile: (code, options, callback) ->
		try
			code = code.toString('utf8')
			md = require('../require')('node-markdown', options)
			callback(null, md.Markdown(code))
		catch err
			callback(err)
