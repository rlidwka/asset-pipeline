Path     = require 'path'
Connect  = require 'connect'
URL      = require 'url'
fs       = require 'fs'
async    = require 'async'
DepMgr   = require './depmgr'
MakePath = require './makepath'
util     = require './util'

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
		if @options.debug?
			util.do_log(@options.debug)
		@options.extensions ?= ['.js', '.css']
		@options.extensions =
			@options.extensions.map (x) -> if x[0]=='.' then x else '.'+x
		@builddir = @options.cache # just an alias
		@depmgr = new DepMgr(@options.assets)
		@servers =
			normal: Connect.static(@options.cache)
			caching: Connect.static(@options.cache, { maxAge: 365*24*60*60 })
		for file in (@options.files ? [])
			@files[Path.join('/',file)] = { serve: true }

	can_serve_file: (file) ->
		if @files[file]?.serve
			return true
		for ext in @options.extensions when Path.extname(file) == ext
			return true
		return false

	middleware: -> (req, res, next) =>
		url = URL.parse(req.url)
		path = decodeURIComponent(url.pathname)
		file = Path.join('/', path)
		if @can_serve_file(file)
			util.log('trying to serve ' + file)
			server = if @files[file]?.cache then @servers.caching else @servers.normal
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

		if not @files[file]?.compiled
			# file is not compiled yet
			@compile_file(file, (err) =>
				if err
					if err?.code == 'asset-pipeline/filenotfound'
						return next() # just pass to next
					else
						return next(err)
				server(req, res, safeNext)
			)
		else if @files[file].cache
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
		util.log "compiling #{file}"
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
			if err
				@depmgr.resolves_to(file, null)
				return run_callbacks(err)
			@depmgr.resolves_to(file, found.path)
			@send_to_pipeline(file, found.path, found.extlist, (err) =>
				@files[file] ?= {}
				@files[file].compiled = true unless(err)
				run_callbacks(err)
			)
		)

	actual_pipeline: (data, pipes, filename, attrs, cb) ->
		return cb(null, data) if pipes.length == 0
		pipe = pipes.shift()
		if pipe.ext == ''
			return @actual_pipeline(data, pipes, pipe.file, attrs, cb)
		unless @plugins[pipe.ext].compile
			return cb(new Error('compiler not found'))
		attrs.filename = pipe.file
		oldfile = @path_to_req(filename)
		newfile = @path_to_req(pipe.file)
		@depmgr.clear_deps(newfile)
		@depmgr.depends_on(newfile, oldfile)
		attrs.filename = pipe.file
		@plugins[pipe.ext].compile(data, attrs, (err, result) =>
			return cb(err) if err
			@actual_pipeline(result, pipes, pipe.file, attrs, cb)
		)

	send_to_pipeline: (reqfile, file, plugins, cb) ->
		dest = Path.join(@options.cache, reqfile)
		@depmgr.clear_deps(@path_to_req(file))
		fs.readFile(file, 'utf8', (err, data) =>
			return cb(err) if (err)
			console.log('+================', plugins)
			@actual_pipeline(data, plugins, file, {pipeline:@}, (err, data) =>
				return cb(err) if (err)
				util.write_file(dest, data, cb)
			)
		)

	path_to_req:   (path) -> Path.join('/', Path.relative(@options.assets, path))
	path_to_cache: (path) -> Path.join(@options.cache, @path_to_req(path))
	req_to_cache:  (path) -> Path.join(@options.cache, path)

module.exports = Pipeline

