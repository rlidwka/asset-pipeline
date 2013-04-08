Path = require './path'
fs   = require 'fs'
util = require 'util'
async = require 'async'
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
	# atomic replacing with temp file to avoid race conditions
	safe_write = (cb) ->
		tmpname = dest + '.tmp'+String(Math.random()).substr(2, 5)
		fs.writeFile(tmpname, data, (err) ->
			return cb(err) if err
			fs.rename(tmpname, dest, cb)
		)

	safe_write((err) ->
		if err?.code == 'ENOENT'
			make_directories(dest, ->
				safe_write(cb)
			)
		else
			cb(err)
	)

_NoConcurrentCache = {}
exports.NoConcurrent = NoConcurrent = (key, cb, func) ->
	if _NoConcurrentCache[key]?
		_NoConcurrentCache[key].push(cb)
		return
	_NoConcurrentCache[key] = [cb]
	func ->
		old_queue = _NoConcurrentCache[key]
		delete _NoConcurrentCache[key]
		for func in old_queue
			func.apply(null, arguments)

exports.link_file = (src, dst, maincb) ->
	# atomic replacing with temp file to avoid race conditions
	safe_link = (cb) ->
		tmpname = dst + '.tmp'+String(Math.random()).substr(2, 8)
		fs.link(src, tmpname, (err) ->
			return cb(err) if err
			fs.rename(tmpname, dst, (err) ->
				cb(err)

				# If oldpath and newpath are existing hard links referring to the same file,
				# then rename() does nothing, and returns a success status.
				fs.unlink(tmpname, ->)
			)
		)

	NoConcurrent("link #{dst}", maincb, (cb) ->
		safe_link((err) ->
			if err?.code == 'ENOENT'
				make_directories(dst, ->
					safe_link(cb)
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
