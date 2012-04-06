
# ejs.func = (a, b, c) ->
# ejs.func = Wrapper(func)

# hashes

fs     = require 'fs'
async  = require 'async'
Path   = require 'path'
crypto = require 'crypto'
util   = require './util'

escape_chars = ['\\', '&', '\'', '"', '<', '>']

monads = {}
Monad = (@fn) ->
	@id = Math.round(Math.random()*1e16)
	monads[@id] = @
	return @

Monad::toString = -> "[Monad #{@id},#{escape_chars.join(',')}]"
Monad::unWrap = (cb) ->
	@fn (err, res) =>
		return cb(err) if err
		cb(null, @_doReplace(res))

Monad::_doReplace = ->
Monad::_setReplace = (str) ->
	@_doReplace = (code) ->
		for repl,idx in str.split(',') when orig = escape_chars[idx]
			code = code.split(orig).join(repl)
		return code
	return @

Callback = ->
	@callbacks = []
	return @

Callback::set = (args) ->
	@args = args
	for cb in @callbacks
		cb.apply(null, @args)
	@callbacks = []

Callback::func = ->
	(cb) =>
		if @args?
			cb.apply(null, @args)
		else
			@callbacks.push(cb)

Wrap = (fn) -> -> new Monad(fn.apply(@, arguments))

module.exports.call = (code, maincb) ->
	fns = code.match(/\[Monad [^\]]+\]/g) || []
	fns = fns.map((fn) ->
		m = fn.match(/\[Monad (\d{2,16}),([^\]]+)\]/)
		return null unless m? and monads[m[1]]?
		(cb) ->
			monads[m[1]]._setReplace(m[2]).unWrap((err, res) ->
				code = code.replace(m[0], res.replace(/\$/g, '$$$$'))
				cb(err)
			)
	).filter((fn) -> fn)

	async.parallel(fns, (err) ->
		maincb(err, code)
	)

# options.once
# options.jsformat
module.exports.prepare = (gopts) ->
	pipeline = gopts.pipeline
	filename = pipeline.path_to_req(gopts.filename)
	Inlines = {}

	get_file = (file, cb) ->
		file = Path.resolve(Path.dirname(filename), file)
		pipeline.compile_file(file, (err) ->
			return cb(err) if err
			fs.readFile(pipeline.req_to_cache(file), (err) ->
				pipeline.depmgr.depends_on(filename, file) unless err
				cb.apply(null, arguments)
			)
		)

	compile_file = (file, cb) ->
		file = Path.resolve(Path.dirname(filename), file)
		pipeline.compile_file(file, (err, rec) ->
			return cb(err) if err
			pipeline.depmgr.depends_on(filename, file)
			cb(err, pipeline.req_to_cache(file), rec)
		)

	get_digest = (file, cb) ->
		pipeline._digest_cache ?= {}
		compile_file(file, (err, _, wasrecompiled) ->
			return cb(err) if err
			if !wasrecompiled and pipeline._digest_cache[file]?
				return cb(null, pipeline._digest_cache[file])
			fs.readFile(pipeline.req_to_cache(file), (err, data) ->
				return cb(err) if err
				md5 = crypto.createHash('md5')
				res = md5.update(data).digest('base64')
				res = res.replace(/[^A-Za-z0-9]/g, '').substr(0, 8)
				pipeline._digest_cache[file] = res
				cb(null, res)
			)
		)
	
	Inlines.asset_include = Wrap (file, options = {}) ->
		callback = new Callback()
		file = Path.resolve(Path.dirname(filename), file)
		get_file(file, (err) ->
			results = arguments
			unless err
				results[1] = results[1].toString 'utf8'
				if options.jsescape
					results[1] = results[1].
						replace(/\\/g, '\\\\').
						replace(/\n/g, '\\n').
						replace(/'/g, '\\\'').
						replace(/"/g, '\\\"')
			callback.set(results)
		)
		return callback.func()

	Inlines.asset_include_dir = Wrap (file, options = {}) ->
		(cb) -> cb('not supported yet')

	Inlines.asset_include_path = Wrap (file, options = {}) ->
		(cb) -> cb('not supported yet')

	Inlines.asset_require = Wrap (file, options = {}) ->
		(cb) -> cb('not supported yet')

	Inlines.asset_require_dir = Wrap (file, options = {}) ->
		(cb) -> cb('not supported yet')

	Inlines.asset_require_path = Wrap (file, options = {}) ->
		(cb) -> cb('not supported yet')

	Inlines.asset_depend_on = Wrap (file) ->
		callback = new Callback()
		pipeline.compile_file(file, (err) ->
			pipeline.depmgr.depends_on(filename, file) unless err
			callback.set(arguments)
		)
		return callback.func()

	Inlines.asset_digest = Wrap (file, options = {}) ->
		callback = new Callback()
		file = Path.resolve(Path.dirname(filename), file)
		get_digest(file, (err, digest) ->
			return callback.set(arguments) if err
			callback.set([null, digest])
		)
		return callback.func()

	Inlines.asset_size = Wrap (file, options = {}) ->
		(cb) -> cb('not supported yet')

	Inlines.asset_mtime = Wrap (file, options = {}) ->
		(cb) -> cb('not supported yet')

	Inlines.asset_ctime = Wrap (file, options = {}) ->
		(cb) -> cb('not supported yet')

	Inlines.asset_uri = Wrap (file, options = {}) ->
		callback = new Callback()
		file = Path.resolve(Path.dirname(filename), file)
		get_digest(file, (err, digest) ->
			return callback.set(arguments) if err
			base = (Path.basename(file).match(/^[0-9A-Za-z]{1,5}/) ? [''])[0]
			base = base.substr(0,3) if base.length >= 5
			ext = Path.extname(file)
			result = Path.join(Path.dirname(file), "#{base}-#{digest}#{ext}")
			pipeline.register(file, result, (err) ->
				return callback.set([err]) if err
				callback.set([null, result])
			)
		)
		return callback.func()

	Inlines.asset_echo = Wrap (msg) ->
		(cb) -> cb(null, msg)

	return Inlines

###
Debug = (name, fn) ->
	(args...) ->
		console.log("function #{name} called, args=[#{args.join(',')}]")
		fn.call(@, args...)
		console.log("function #{name} finished")

somefunction = Debug 'somefunction', (x) ->
	otherfunction(x+1)

otherfunction = Debug 'otherfunction', (x) ->
	x+2

somefunction(1)
###


#require('coffee-script').eval(require('fs').readFileSync("filename.coffee"))

