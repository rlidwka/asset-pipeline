module.exports =
	source: 'md'
	target: 'html'
	compile: (code, options, callback) ->
		try
			md = require('node-markdown').Markdown
			callback(null, md(code))
		catch err
			callback(err)
