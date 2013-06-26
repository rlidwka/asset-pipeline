
# ejs.func = (a, b, c) ->
# ejs.func = Wrapper(func)

# hashes

fs     = require 'fs'
async  = require 'async'
Path   = require './path'
crypto = require 'crypto'
util   = require './util'
Cache  = require 'async-cache'

# generate random string
gen_code = (length) ->
	code = ''
	chars = 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM'
	for i in [0...length]
		code += chars[Math.floor(Math.random()*chars.length)]
	return code

# it should be guaranteed that this will never be in user data
START_SEQ = gen_code(12)
END_SEQ = gen_code(4)

# incremental number of a function
FuncID = 0

escape_chars = ['\\', '&', '\'', '"', '<', '>']

monads = {}
Monad = (@fn) ->
	@id = FuncID++
	if (FuncID > 1e15) then FuncID = 0
	monads[@id] = @
	return @

Monad::toString = -> "#{START_SEQ}#{@id},#{escape_chars.join(',')}#{END_SEQ}"
Monad::unWrap = (cb) ->
	@fn (err, res) =>
		delete monads[@id]
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

# it is just very optimized replace of a number of these sequences:
# START_SEQ + id + ',' + replace + END_SEQ
inlines_call = (orig, result, pos, cb) ->
	newpos = orig.indexOf(START_SEQ, pos)
	if newpos == -1 then return cb(null, result + orig.substr(pos))
	result += orig.substr(pos, newpos-pos)

	pos = newpos + START_SEQ.length
	newpos = orig.indexOf(',', pos)
	id = orig.substr(pos, newpos-pos)

	pos = newpos+1
	newpos = orig.indexOf(END_SEQ, newpos)
	replace = orig.substr(pos, newpos-pos)

	monads[id]._setReplace(replace).unWrap((err, res) ->
		return cb(err) if err
		process.nextTick ->
			inlines_call(orig, result + res, newpos+END_SEQ.length, cb)
	)

module.exports.call = (code, cb) ->
	inlines_call(code, '', 0, cb)

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
		pipeline._digest_cache ?= new Cache(
			max: 10000,
			maxAge: 2*60*60*1000,
			load: (file, cb) ->
				fs.readFile(pipeline.req_to_cache(file), (err, data) ->
					return cb(err) if err
					md5 = crypto.createHash('md5')
					res = md5.update(data).digest('base64')
					res = res.replace(/[^A-Za-z0-9]/g, '').substr(0, 8)
					pipeline._digest_cache[file] = res
					cb(null, res)
				)
		)
		compile_file(file, (err, _, wasrecompiled) ->
			return cb(err) if err
			if wasrecompiled
				pipeline._digest_cache.del(file)
			pipeline._digest_cache.get(file, cb)
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
			pipeline.register(file, result, (err, final_uri) ->
				return callback.set([err]) if err
				callback.set([null, final_uri])
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

