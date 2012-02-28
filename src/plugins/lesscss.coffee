cssimport = require '../cssimport'

css_compiler = (code, options, callback) ->
	less = require 'less'
	util = require 'util'
	parser = new(less.Parser)(
		paths: [options.assets_path]
		filename: options.filename
	)
	parser.parse(code, (err, tree) ->
		return callback(new Error(util.inspect(err))) if (err)
		callback(null, tree.toCSS())
	)

module.exports =
	source: 'less'
	target: 'css'
	compile: (code, options, callback) ->
		cssimport.search_deps(options, (err) ->
			return callback(err) if err
			try
				css_compiler(code, options, callback)
			catch err
				callback(err)
		)
