module.exports =
	source: 'md'
	target: 'html'
	compile: (code, options, callback) ->
		try
			code = code.toString('utf8')
			md = require('node-markdown').Markdown
			callback(null, md(code))
		catch err
			callback(err)
