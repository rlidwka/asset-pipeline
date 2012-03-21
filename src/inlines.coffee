
# ejs.func = (a, b, c) ->
# ejs.func = Wrapper(func)

# hashes

fs = require 'fs'
async = require 'async'
module.exports.list = Inlines = {}

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

Wrap = (fn) -> -> new Monad(fn.apply(@, arguments))

module.exports.call = (code, maincb) ->
	fns = code.match(/\[Monad [^\]]+\]/g) || []
	fns = fns.map((fn) ->
		m = fn.match(/\[Monad (\d{2,16}),([^\]]+)\]/)
		return null unless m? and monads[m[1]]?
		(cb) ->
			monads[m[1]]._setReplace(m[2]).unWrap((err, res) ->
				code = code.replace(m[0], res)
				cb(err)
			)
	).filter((fn) -> fn)

	async.parallel(fns, (err) ->
		maincb(err, code)
	)

# options.once
# options.jsformat
Inlines.asset_include = Wrap (file, options = {}) ->
	fs.readFile.bind(@, file)

Inlines.asset_include_dir = Wrap (file, options = {}) ->
	fs.readFile.bind(@, file)

Inlines.asset_include_path = Wrap (file, options = {}) ->
	fs.readFile.bind(@, file)

Inlines.asset_require = Wrap (file, options = {}) ->
	fs.readFile.bind(@, file)

Inlines.asset_require_dir = Wrap (file, options = {}) ->
	fs.readFile.bind(@, file)

Inlines.asset_require_path = Wrap (file, options = {}) ->
	fs.readFile.bind(@, file)

Inlines.asset_depend_on = Wrap (file, options = {}) ->
	fs.readFile.bind(@, file)

Inlines.asset_digest = Wrap (file, options = {}) ->
	fs.readFile.bind(@, file)

Inlines.asset_md5 = Wrap (file, options = {}) ->
	fs.readFile.bind(@, file)

Inlines.asset_size = Wrap (file, options = {}) ->
	fs.readFile.bind(@, file)

Inlines.asset_mtime = Wrap (file, options = {}) ->
	fs.readFile.bind(@, file)

Inlines.asset_ctime = Wrap (file, options = {}) ->
	fs.readFile.bind(@, file)

Inlines.asset_atime = Wrap (file, options = {}) ->
	fs.readFile.bind(@, file)

Inlines.asset_uri = Wrap (file, options = {}) ->
	'/some-file.txt'

Inlines.asset_echo = Wrap (msg) ->
	(cb) -> cb(null, msg)

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

