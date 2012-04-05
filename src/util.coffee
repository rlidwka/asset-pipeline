Path = require 'path'
fs   = require 'fs'
util = require 'util'
_do_log = process.env.NODE_DEBUG && /asset\-pipeline/.test(process.env.NODE_DEBUG)

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
	fs.unlink(dest, ->
		fs.writeFile(dest, data, (err) ->
			if err?.code == 'ENOENT'
				make_directories(dest, ->
					fs.writeFile(dest, data, cb)
				)
			else
				cb(err)
		)
	)

exports.link_file = (src, dst, cb) ->
	fs.unlink(dst, ->
		fs.link(src, dst, (err) ->
			if err?.code == 'ENOENT'
				make_directories(dst, ->
					fs.link(src, dst, cb)
				)
			else
				cb(err)
		)
	)

exports.do_log = (arg) ->
	_do_log = !!arg if arg?
	_do_log

exports.log = (args...) ->
	util.log(args...) if _do_log
