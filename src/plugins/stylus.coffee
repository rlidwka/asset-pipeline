cssimport = require '../cssimport'
Path      = require 'path'

module.exports =
	source: 'styl'
	target: 'css'
	compile: (code, options, callback) ->
		cssimport.search_deps(code, options, 'styl', (err, newfilename) ->
			return callback(err) if err
			options.filename = newfilename if newfilename
			try
				stylus = require 'stylus'
				stylus(code).set('paths', [
					Path.dirname(options.filename)
				]).set(
					filename: options.filename
				).render(callback)
			catch err
				callback(err)
		)
