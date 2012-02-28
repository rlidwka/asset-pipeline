module.exports =
	source: 'md'
	target: 'html'
	compile: (code, options, callback) ->
		md = require('node-markdown').Markdown
		try
			callback(null, md(code))
		catch err
			callback(err)
