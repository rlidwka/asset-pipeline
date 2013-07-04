Path     = require './path'
Send     = require 'send'
URL      = require 'url'
fs       = require 'fs'
async    = require 'async'
crypto   = require 'crypto'
DepMgr   = require './depmgr'
MakePath = require './makepath'
util     = require './util'
Inlines  = require './inlines'

class Pipeline
	constructor: (@options) ->
		# we are serving these files to the client
		@files = {}

		# queue = {file: [callbacks array]}
		@id = Math.random()

		@options.assets ?= './assets'
		@options.assets = Path.normalize(@options.assets)
		@options.cache ?= './cache'
		@options.cache = Path.normalize(@options.cache)
		@options.mount_point ?= ''
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

		# setup servers
		server = (set_maxage = false) => (req, res, _next) =>
			# fix for post and other requests with content data
			req.pause()
			next = (err) ->
				req.resume()
				_next(err)
			
			sender = Send(req, URL.parse(req.url).pathname)
			sender.root(@staticDir)
			sender.maxage(365*24*60*60*1000) if set_maxage
			sender.on('directory', () -> next(new Error('directory found')))
			sender.on('error', (err) -> next(err))
			sender.pipe(res)

		@servers =
			normal: server(false)
			caching: server(true)

		for file in (@options.files ? [])
			@files[Path.join('/',file)] = { serve: true }
		@inlines = Inlines.prepare(filename: '/', pipeline: @)
		@load_cache_state()

	# check if this file can be served directly
	can_serve_file: (file) ->
		if @files[file]?.serve
			return true
		for ext in @options.extensions when Path.extname(file) == ext
			return true
		return false

	# loading cache state (usually on startup)
	load_cache_state: ->
		# change it if contents format is updated
		@options.__json_version = 1

		hash = crypto.createHash('md5')
		hash.update(JSON.stringify(@options))
		name = hash.digest('base64').replace(/[^A-Za-z0-9]/g, '').substr(0, 12)
		@state_filename = Path.join(@tempDir, name + '.json')
		fs.readFile(@state_filename, (err, res) =>
			return if err
			try
				object = JSON.parse(res)
				@files = object.files
				@depmgr.set_state(object.depmgr)
				util.log('state loaded successfully from ' + @state_filename)
		)

	save_cache_state: (cb) ->
		# pause at least 20 sec between writes 
		return if Number(new Date()) < @_state_last_written + 20000
		@_state_last_written = Number(new Date())

		# defer 2 sec before writing because application is probably
		# quite busy at the time this function called
		setTimeout(=>
			@_state_last_written = Number(new Date())
			util.log('saving state to ' + @state_filename)
			fs.writeFile(@state_filename, JSON.stringify({
				files: @files
				depmgr: @depmgr.get_state()
			}), cb)
		, 2000)

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

					# default function
					if 'function' != typeof fn
						fn = (err, code) ->
							return req.next(err) if err
							res.send(code)

					#options[name] ?= value for name,value of @inlines
					oldrender.call(res, view, options, (err, code) =>
						return fn(err) if err
						Inlines.call(code, fn)
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
			@servers.caching(req, res, next)
			#next()

	get_file: (file, cb) ->
		relcwd = Path.relative(@options.assets, process.cwd())
		file = Path.resolve('/'+relcwd, file)
		@compile_file(file, (err) =>
			return cb(err) if err
			fs.readFile(@req_to_cache(file), (err) =>
				cb.apply(null, arguments)
			)
		)

	serve_file: (req, res, file, server, next) ->
		if @files[file]?.compiled and @files[file].cache
			# file is static with md5, never changes
			server(req, res, next)
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
					server(req, res, next)
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
						@save_cache_state()
					cb(err, true)

				MakePath.find(@options.assets, file, (err, found) =>
					if err
						@depmgr.resolves_to(file, null)
						return cb(err)
					@depmgr.resolves_to(file, found.path)
					@send_to_pipeline(file, found.path, found.extlist, (err) =>
						return cb(err) if err
						# republish it
						delete @files[file]?.published
						@publish_file(file, finish)
					)
				)
			)

	publish_file: (file, cb) ->
		if @files[file]? && @files[file].serve && !@files[file].published
			util.link_file(@req_to_cache(file), @req_to_static(file), (err) =>
				@files[file].published = yes unless err
				cb(err)
			)
		else
			cb()

	actual_pipeline: (data, pipes, filename, attrs, cb) ->
		return cb(null, data) if pipes.length == 0
		data = data.toString('utf8')
		pipe = pipes.shift()
		if pipe.ext == ''
			return @actual_pipeline(data, pipes, pipe.file, attrs, cb)
		Compiler = MakePath.mappings[pipe.ext]?[pipe.dst]
		unless Compiler
			return cb(new Error('compiler not found'))
		oldfile = @path_to_req(filename)
		newfile = @path_to_req(pipe.file)
		@depmgr.clear_deps(newfile)
		@depmgr.depends_on(newfile, oldfile)
		attrs.filename = pipe.file

		# plugin-dependent configs
		# try both ".ext" and "ext"
		if @options.plugin_config?
			attrs.plugin_config =
				@options.plugin_config[pipe.ext] ?
				@options.plugin_config[pipe.ext.replace(/^\./)]

		if @options.dependencies?
			attrs.dependencies = @options.dependencies

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
			cb(null, Path.join(@options.mount_point, static_name))
		)

	path_to_req:   (path) -> Path.join('/', Path.relative(@options.assets, path))
	path_to_cache: (path) -> Path.join(@tempDir, @path_to_req(path))
	req_to_cache:  (path) -> Path.join(@tempDir, path)
	req_to_static: (path) -> Path.join(@staticDir, path)

module.exports = Pipeline

