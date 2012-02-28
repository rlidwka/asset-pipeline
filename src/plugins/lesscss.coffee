module.exports =
	source: 'less'
	target: 'css'
	compile: (code, options, callback) ->
		less = require 'less'
		try
			parser = new(less.Parser)(filename: options.filename)
			parser.parse(code, (err, tree) ->
				callback(err) if (err)
				callback(null, tree.toCSS())
			)
		catch err
			callback(err)
