cssimport = require '../cssimport'
Path      = require 'path'
util      = require 'util'

css_compiler = (code, options, callback) ->
	less = require 'less'
	parser = new(less.Parser)(
		paths: [
			Path.dirname(options.filename)
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
		cssimport.search_deps(code, options, 'less', (err, newfilename) ->
			return callback(err) if err
			options.filename = newfilename if newfilename
			try
				css_compiler(code, options, callback)
			catch err
				return callback(new Error(util.inspect(err))) if (err)
		)
