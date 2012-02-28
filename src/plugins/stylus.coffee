cssimport = require '../cssimport'

module.exports =
	source: 'styl'
	target: 'css'
	compile: (code, options, callback) ->
		cssimport.search_deps(options, (err) ->
			return callback(err) if err
			try
				stylus = require 'stylus'
				stylus.render(code, {filename: options.filename}, callback)
			catch err
				callback(err)
		)
