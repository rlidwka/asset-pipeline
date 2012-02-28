Path     = require 'path'
Connect  = require 'connect'
URL      = require 'url'
fs       = require 'fs'
async    = require 'async'
DepMgr   = require './depmgr'
MakePath = require './makepath'

class Pipeline
	constructor: (@options, @plugins) ->
		# we are serving these files to the client
		@files = {}
		# queue = {file: [callbacks array]}
		@compile_queue = {}

		@options.assets ?= './assets'
		@options.assets = Path.normalize(@options.assets)
		@options.cache ?= './cache'
		@options.cache = Path.normalize(@options.cache)
		@builddir = @options.cache # just an alias
		@depmgr = new DepMgr(@options.assets)
		@servers =
			normal: Connect.static(@options.cache)
			caching: Connect.static(@options.cache, { maxAge: 365*24*60*60 })
		for file in (@options.files ? [])
			@files[Path.join('/',file)] = { nocache: true, serve: true }

	middleware: -> (req, res, next) =>
		url = URL.parse(req.url)
		path = decodeURIComponent(url.pathname)
		file = Path.join('/', path)
		if @files[file]?.serve
			server = if @files[file].nocache then @servers.normal else @servers.caching
			@serve_file(req, res, file, server, next)
		else
			next()

	serve_file: (req, res, file, server, next, safe=1) ->
		safeNext = next
		if safe then safeNext = (err) =>
			# it's in case someone has deleted our caches
			return next(err) if (err)
			@files[file].compiled = false
			@serve_file(req, res, file, server, next, 0)

		if not @files[file].compiled
			# file is not compiled yet
			@compile_file(file, (err) =>
				return next(err) if (err)
				server(req, res, safeNext)
			)
		else if not @files[file].nocache
			# file is static with md5, never changes
			server(req, res, safeNext)
		else
			# file can be changed, checking deps
			@depmgr.check(file, (err, changed) =>
				return next(err) if (err)
				if changed
					@files[file].compiled = false
					@serve_file(req, res, file, server, next)
				else
					server(req, res, safeNext)
			)

	compile_file: (file, cb) ->
		@files[file] ?= file
		if @compile_queue[file]?
			@compile_queue[file].push(cb)
			return
		@compile_queue[file] = [cb]
		run_callbacks = (args...) =>
			old_queue = @compile_queue[file]
			delete @compile_queue[file]
			args.unshift(null)
			async.parallel(old_queue.map((f)->f.bind.apply(f, args)))

		MakePath.find(@options.assets, file, (err, found) =>
			return run_callbacks(err) if err
			@send_to_pipeline(found.path, Path.join(@options.cache, file), found.extlist, (err) =>
				@files[file].compiled = true unless(err)
				run_callbacks(err)
			)
		)

	actual_pipeline: (data, pipes, attrs, cb) ->
		return cb(null, data) if pipes.length == 0
		pipe = pipes.shift()
		if pipe == ''
			return actual_pipeline(data, pipes, attrs, cb)
		unless @plugins[pipe].compile
			return cb(new Error('compiler not found'))
		@plugins[pipe].compile(data, attrs, (err, result) =>
			return cb(err) if err
			@actual_pipeline(result, pipes, attrs, cb)
		)

	send_to_pipeline: (file, dest, plugins, cb) ->
		fs.readFile(file, 'utf8', (err, data) =>
			return cb(err) if (err)
			@actual_pipeline(data, plugins, {filename:file, pipeline:@}, (err, data) =>
				return cb(err) if (err)
				write_file(dest, data, cb)
			)
		)

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

write_file = (dest, data, cb) ->
	fs.writeFile(dest, data, (err) ->
		if err?.code == 'ENOENT'
			make_directories(dest, ->
				fs.writeFile(dest, data, cb)
			)
		else
			cb(err)
	)

module.exports = Pipeline

