module.exports =
	source: 'less'
	target: 'css'
	compile: (code, options, callback) ->
		less = require 'less'
		util = require 'util'
		try
			parser = new(less.Parser)(
				paths: [options.assets_path]
				filename: options.filename
			)
			parser.parse(code, (err, tree) ->
				return callback(new Error(util.inspect(err))) if (err)
				callback(null, tree.toCSS())
			)
		catch err
			callback(err)
