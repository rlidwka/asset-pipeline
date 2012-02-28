fs      = require 'fs'
async   = require 'async'
connect = require 'connect'
Path    = require 'path'
URL     = require 'url'
DepMgr  = require './depmgr'

# we are serving these files to the client
# files = {filename: [dependencies array here]}
files = {}

# timestamps are here
sources = {}

# plugins = {name: {... , require: (lazy require function here)} }
plugins = {}

# source extension -> target extension
mappings = {}

###
# adds file to the cache
file_found = (path, stats) ->
	ext = Path.extname(path)
	while ext.length > 0
		path = Path.basename(path, ext)
		ext = Path.extname(path)
###

###
# this function scans assets dir for given partial filename
find_file = (path, file, cb) ->
	fs.readdir(path, (err, files) ->
		return cb(err) if err
		async.forEach(files.map(Path.join.bind(Path, path), (() ->
		
		), cb)
	)


	fs.stat(path, (err, stats) ->
		return cb(err) if err
		if stats.isDirectory()
			fs.readdir(path, (err, files) ->
				return cb(err) if err
				async.forEach(files.map(Path.join.bind(Path, path), rescan_file, cb)
			)
		else
			file_found(path, stats)
			cb()
	)
###

get_make_path = (from, to, oldpath = [], seen = {}) ->
	return null if oldpath.length > 10 # infinite loop?
	return null if seen[from] # loop
	seen[from] = 1

	#console.log "probing #{to} == #{from}"
	if from == to then return oldpath

	ext = Path.extname(from)
	return null if ext == '' or !mappings[ext]?
	from = Path.basename(from, ext)
	min = Infinity
	minpath = null
	for newext in mappings[ext]
		newpath = oldpath.slice(0).concat(ext)
		res = get_make_path(from+newext, to, newpath, seen)
		if res? and res.length < min
			min = res.length
			minpath = res
	return minpath

# this function scans assets dir for given partial filename
find_file = (path, file, maincb) ->
	search_for = Path.join(path, file)
	base = Path.basename(search_for)
	beginning = base.substr(0, base.indexOf('.')) || base
	fs.readdir(Path.dirname(search_for), (err, files) ->
		maincb(err) if err
		results = []

		found = path:'', extlist:[]
		for foundfile in files when foundfile.indexOf(beginning) == 0
			makepath = get_make_path(foundfile, base)
			console.log(foundfile, base, mappings)
			if makepath? and found.extlist.length <= makepath.length
				found.path = foundfile
				found.extlist = makepath
		if found.path == ''
			maincb(new Error('File not found'))
		else
			maincb(err, found)
	)

actual_pipeline = (data, pipes, options, cb) ->
	return cb(null, data) if pipes.length == 0
	pipe = pipes.shift()
	if pipe == ''
		return actual_pipeline(data, pipes, options, cb)
	unless plugins[pipe].compile
		return cb(new Error('compiler not found'))
	plugins[pipe].compile(data, options, (err, result) ->
		return cb(err) if err
		actual_pipeline(result, pipes, options, cb)
	)

send_to_pipeline = (options, file, dest, plugins, cb) ->
	fs.readFile(file, 'utf8', (err, data) ->
		return cb(err) if (err)
		actual_pipeline(data, plugins, {filename:file, assets_path:options.assets}, (err, data) ->
			return cb(err) if (err)
			fs.writeFile(dest, data, cb)
		)
	)

# queue = {file: [callbacks array]}
compile_queue = {}
compile_file = (options, file, cb) ->
	if compile_queue[file]?
		compile_queue[file].push(cb)
		return
	compile_queue[file] = [cb]
	run_callbacks = (args...) ->
		old_queue = compile_queue[file]
		delete compile_queue[file]
		args.unshift(null)
		async.parallel(old_queue.map((f)->f.bind.apply(f, args)))

	find_file(options.assets, file, (err, found) ->
		return run_callbacks(err) if err
		send_to_pipeline(options, Path.join(options.assets, found.path), Path.join(options.cache, file), found.extlist, (err) ->
			files[file].compiled = true unless(err)
			run_callbacks(err)
		)
	)

check_deps = (file, cb) ->
	return cb(null, true)

serve_file = (options, req, res, file, server, next, safe=1) ->
	safeNext = next
	if safe then safeNext = (err) ->
		# it's in case someone has deleted our caches
		console.log('safenext catch')
		return next(err) if (err)
		files[file].compiled = false
		serve_file(options, req, res, file, server, next, 0)

	if not files[file].compiled
		# file is not compiled yet
		compile_file(options, file, (err) ->
			return next(err) if (err)
			server(req, res, safeNext)
		)
	else if not files[file].nocache
		# file is static with md5, never changes
		server(req, res, safeNext)
	else
		# file can be changed, checking deps
		check_deps(file, (err, changed) ->
			return next(err) if (err)
			if changed
				files[file].compiled = false
				serve_file(options, req, res, file, server, next)
			else
				server(req, res, safeNext)
		)
	
pipeline_middleware = (options, servers) ->
	(req, res, next) ->
		url = URL.parse(req.url)
		path = decodeURIComponent(url.pathname)
		file = Path.join('/', path)
		if files[file]?
			server = if files[file].nocache then servers.normal else servers.caching
			serve_file(options, req, res, file, server, next)
		else
			next()

module.exports = asset_pipeline_factory = (config = {}) ->
	config.assets ?= './assets'
	config.assets = Path.normalize(config.assets)
	config.cache ?= './cache'
	config.cache = Path.normalize(config.cache)
	depmgr = new DepMgr(config.assets)
	servers =
		normal: require('connect').static(config.cache)
		caching: require('connect').static(config.cache, { maxAge: 365*24*60*60 })
	for file in (config.files ? [])
		files[Path.join('/',file)] = { nocache: true }

	return pipeline_middleware(config, servers)

# load plugins (lazily, just as in connect)
load_plugins = ->
	for filename in fs.readdirSync(__dirname + '/plugins')
		name = Path.basename(filename, Path.extname(filename))
		try
			plugin = require('./plugins/' + filename)
			if plugin.compile
				console.log filename
				plugin.source = [plugin.source] if typeof(plugin.source) == 'string'
				plugin.target = [plugin.target] if typeof(plugin.target) == 'string'
				if plugin.source
					for ext in plugin.source
						plugins['.'+ext] = plugin
						mappings['.'+ext] = ['']
						if plugin.target?
							for te in plugin.target
								mappings['.'+ext].push('.'+te.replace(/^\./g, ''))
		catch err

load_plugins()
