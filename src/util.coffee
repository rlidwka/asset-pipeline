Path = require 'path'
fs   = require 'fs'
_do_log = false

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

module.exports.write_file = (dest, data, cb) ->
	fs.writeFile(dest, data, (err) ->
		if err?.code == 'ENOENT'
			make_directories(dest, ->
				fs.writeFile(dest, data, cb)
			)
		else
			cb(err)
	)

module.exports.do_log = (arg) -> _do_log = !!arg

module.exports.log = (args...) ->
	console.log(new Date(), args...) if _do_log

