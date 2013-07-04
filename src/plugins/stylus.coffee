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
				stylus = require('../require')('stylus', options)
				inlines = require '../inlines'
				compiler = stylus(code)
				for idx,fn of inlines.prepare(options)
					compiler.define(idx, fn)

				compiler.set('paths', [
					Path.dirname(options.filename)
				]).set(
					filename: options.filename
				).render((err, res) ->
					return callback(err) if err
					inlines.call(res, callback)
				)
			catch err
				callback(err)
		)
