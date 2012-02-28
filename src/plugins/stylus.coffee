cssimport = require '../cssimport'
Path      = require 'path'

module.exports =
	source: 'styl'
	target: 'css'
	compile: (code, options, callback) ->
		cssimport.search_deps(code, options, 'styl', (err) ->
			return callback(err) if err
			try
				stylus = require 'stylus'
				stylus(code).set('paths', [
					Path.dirname(options.filename)
					options.pipeline.builddir
				]).set(
					filename: options.filename
				).render(callback)
			catch err
				callback(err)
		)
