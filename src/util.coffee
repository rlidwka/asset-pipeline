Path = require 'path'
fs   = require 'fs'
util = require 'util'
_do_log = false

exports = module.exports = {}

make_directories = (dest, cb) ->
	dir = Path.dirname(dest)
	return cb() if dir == '.' or dir == '..'
	fs.mkdir(dir, (err) ->
		if err?.code == 'ENOENT'
			make_directories(dir, ->
				fs.mkdir(dir, cb)
			)
		else
			cb()
	)

exports.write_file = (dest, data, cb) ->
	fs.writeFile(dest, data, (err) ->
		if err?.code == 'ENOENT'
			make_directories(dest, ->
				fs.writeFile(dest, data, cb)
			)
		else
			cb(err)
	)

exports.do_log = (arg) ->
	_do_log = !!arg if arg?
	_do_log

exports.log = (args...) ->
	util.log(args...) if _do_log


