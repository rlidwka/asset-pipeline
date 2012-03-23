util  = require './util'
fs    = require 'fs'
async = require 'async'

logcheck = (fn) ->
	(file, cb) ->
		fn.call(@, file, (err, res) ->
			util.log(if err
				"file #{file} cannot be checked"
			else if res
				"file #{file} has been changed"
			else
				"file #{file} is the same"
			)
			cb(err, res)
		)

class DepsManager
	constructor: (@base) ->
		@resolving = {}
		@deplist = {}
		# path -> last modified
		@files = {}
		@min_check_time = 500

	clear_deps: (file) ->
		@deplist[file] = {}
	
	depends_on: (file, dep) ->
		util.log "file #{file} depends on #{dep}]"
		@deplist[file][dep] = true

	resolves_to: (file, path) ->
		unless path?
			util.log "file #{file} is not resolved"
			delete @resolving[file]
			return
		util.log "file #{file} is resolved into #{path}"
		@resolving[file] = path
		fs.stat(path, (err, res) =>
			return if err
			@files[path] =
				checked: Date.now()
				mtime: Number(res.mtime)
		)

	_checkFile: (file, cb) ->
		return cb(null, false) unless @resolving[file]?
		path = @resolving[file]
		return cb(null, false) unless @files[path]?
		fs.stat(path, (err, res) =>
			return cb(err) if err
			newtime = Number(res.mtime)
			return cb(null, newtime != @files[path].mtime)
		)

	_checkDeps: (file, cb) ->
		funcs = []
		if @deplist[file]?
			for dep of @deplist[file]
				funcs.push @check.bind(@, dep)
		async.parallel(funcs, (err, res) =>
			return cb(err) if err
			# if one of array is true return true, false otherwise
			return cb(null, !!(1 for i in res when !!i).length)
		)

	check: logcheck (file, cb) ->
		async.parallel [
			@_checkFile.bind(@, file),
			@_checkDeps.bind(@, file)
		], (err, res) =>
			return cb(err) if err
			return cb(null, res[0] || res[1])
###
		return cb(null, false) unless @resolving[file]?
		path = @resolving[file]
		return cb(null, false) unless @files[path]?
		fs.stat(path, (err, res) =>
			return cb(err) if err
			newtime = Number(res.mtime)
			if newtime != @files[path].mtime
				return cb(null, true)

			funcs = []
			if @deplist[path]?
				for dep of @deplist[path]
					funcs.push @check.bind(@, dep)
			async.parallel(funcs, (err, res) =>
				return cb(err) if err
				# if one of array is true return true, false otherwise
				return cb(null, !!(1 for i in res when !!i).length)
			)
		)
###

module.exports = DepsManager

