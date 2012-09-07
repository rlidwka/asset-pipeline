Path     = require 'path'
Connect  = require 'connect'
URL      = require 'url'
fs       = require 'fs'
async    = require 'async'
DepMgr   = require './depmgr'
MakePath = require './makepath'
util     = require './util'
Inlines  = require './inlines'

class Pipeline
	constructor: (@options, @plugins) ->
		# we are serving these files to the client
		@files = {}
		# queue = {file: [callbacks array]}
		@id = Math.random()

		@options.assets ?= './assets'
		@options.assets = Path.normalize(@options.assets)
		@options.cache ?= './cache'
		@options.cache = Path.normalize(@options.cache)
		@tempDir = Path.join(@options.cache, 'tmp')
		@staticDir = Path.join(@options.cache, 'static')
		try fs.mkdirSync(@tempDir)
		try fs.mkdirSync(@staticDir)
		if @options.debug?
			util.do_log(@options.debug)
		@options.extensions ?= ['.js', '.css']
		@options.extensions =
			@options.extensions.map (x) -> if x[0]=='.' then x else '.'+x
		@depmgr = new DepMgr(@options.assets)
		@depmgr.min_check_time = @options.min_check_time ? 1000
		@servers =
			normal: Connect.static(@staticDir)
			caching: Connect.static(@staticDir, { maxAge: 365*24*60*60*1000 })
		for file in (@options.files ? [])
			@files[Path.join('/',file)] = { serve: true }
		@inlines = Inlines.prepare(filename: '/', pipeline: @)

	can_serve_file: (file) ->
		if @files[file]?.serve
			return true
		for ext in @options.extensions when Path.extname(file) == ext
			return true
		return false

	middleware: -> (req, res, realNext) =>
		next = () =>
			oldrender = res.render
			if oldrender?
				res.render = (view, options, fn) =>
					options ?= {}
					if 'function' == typeof options
						fn = options
						options = {}
					res.locals(@inlines)
					#options[name] ?= value for name,value of @inlines
					oldrender.call(res, view, options, (err, code) =>
						return req.next(err) if err
						Inlines.call(code, (err, newcode) =>
							return req.next(err) if err
							return fn(null, newcode) if fn
							res.send(newcode)
						)
					)
			realNext()

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
		
		if @files[file]?.compiled and @files[file].cache
			# file is static with md5, never changes
			server(req, res, safeNext)
		else
			file_defined = @files[file]?
			@files[file] ?= {}
			@files[file].serve = yes
			@compile_file(file, (err) =>
				if err
					delete @files[file] unless file_defined
					if err?.code == 'asset-pipeline/filenotfound'
						return next() # just pass to next
					else
						util.log('ERROR: '+err)
						return next(err)
				util.log("publishing #{file}")
				@publish_file(file, (err) =>
					return next(err) if err
					server(req, res, safeNext)
				)
			)

	check_if_changed: (file, cb) ->
		if !@files[file]?.compiled
			cb()
		else
			@depmgr.check(file, (err, changed) =>
				return cb(err) if err
				@files[file].compiled = false if changed
				cb()
			)

	compile_file: (file, mcb) ->
		@check_if_changed file, (err) =>
			return mcb(err) if (err)
			return mcb(null, false) if @files[file]?.compiled

			util.NoConcurrent("compile #{@id} #{file}", mcb, (cb) =>
				util.log "compiling #{file}"
				finish = (err) =>
					unless err
						@files[file] ?= {}
						util.log "compiled successfully: #{file}"
						@files[file].compiled = true
					cb(err, true)

				MakePath.find(@options.assets, file, (err, found) =>
					if err
						@depmgr.resolves_to(file, null)
						return cb(err)
					@depmgr.resolves_to(file, found.path)
					@send_to_pipeline(file, found.path, found.extlist, (err) =>
						return cb(err) if err
						if @files[file]?.serve
							util.link_file(@req_to_cache(file), @req_to_static(file), (err) =>
								@files[file].published = yes unless err
								finish(err)
							)
						else
							finish(err)
					)
				)
			)

	publish_file: (file, cb) ->
		if @files[file]? && @files[file].serve && !@files[file].published
			util.link_file(@req_to_cache(file), @req_to_static(file), (err) =>
				@files[file].published = yes
				cb()
			)
		else
			cb()

	actual_pipeline: (data, pipes, filename, attrs, cb) ->
		return cb(null, data) if pipes.length == 0
		data = data.toString('utf8')
		pipe = pipes.shift()
		if pipe.ext == ''
			return @actual_pipeline(data, pipes, pipe.file, attrs, cb)
		Compiler = @plugins[pipe.ext]?[pipe.dst]?.compile
		unless Compiler
			return cb(new Error('compiler not found'))
		attrs.filename = pipe.file
		oldfile = @path_to_req(filename)
		newfile = @path_to_req(pipe.file)
		@depmgr.clear_deps(newfile)
		@depmgr.depends_on(newfile, oldfile)
		attrs.filename = pipe.file
		Compiler(data, attrs, (err, result) =>
			return cb(err) if err
			@actual_pipeline(result, pipes, pipe.file, attrs, cb)
		)

	send_to_pipeline: (reqfile, file, plugins, cb) ->
		dest = Path.join(@tempDir, reqfile)
		@depmgr.clear_deps(@path_to_req(file))
		fs.readFile(file, (err, data) =>
			return cb(err) if (err)
			@actual_pipeline(data, plugins, file, {pipeline:@}, (err, data) =>
				return cb(err) if (err)
				util.write_file(dest, data, cb)
			)
		)

	register: (orig_name, static_name, cb) ->
		util.link_file(@req_to_cache(orig_name), @req_to_static(static_name), (err, res) =>
			return cb(err) if err
			@files[static_name] =
				cache: yes
				serve: yes
				compiled: yes
				published: yes
			cb()
		)

	path_to_req:   (path) -> Path.join('/', Path.relative(@options.assets, path))
	path_to_cache: (path) -> Path.join(@tempDir, @path_to_req(path))
	req_to_cache:  (path) -> Path.join(@tempDir, path)
	req_to_static: (path) -> Path.join(@staticDir, path)

module.exports = Pipeline

