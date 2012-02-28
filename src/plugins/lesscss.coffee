cssimport = require '../cssimport'
Path      = require 'path'

css_compiler = (code, options, callback) ->
	less = require 'less'
	util = require 'util'
	parser = new(less.Parser)(
		paths: [
			Path.dirname(options.filename)
			options.pipeline.builddir
		]
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
		cssimport.search_deps(code, options, 'less', (err) ->
			return callback(err) if err
			try
				css_compiler(code, options, callback)
			catch err
				callback(err)
		)
