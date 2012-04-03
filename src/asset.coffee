Pipeline = require './pipeline'
Plugins  = require './plugins'
Path     = require 'path'
fs       = require 'fs'
rimraf   = require 'rimraf'
optimist = require('optimist')
	.check( (argv) -> if argv._.length == 0 then throw "" else true )
	.check( (argv) -> if argv._.length != 1 then throw "Wrong parameters" else true )
	.usage("Usage: $0 file")

Argv = optimist.argv

getTemp = ->
	def = '/tmp'
	env = ['TMPDIR', 'TMP', 'TEMP']

	for i in env when value = process.env[env[i]]
		return fs.realpathSync(value)
	return fs.realpathSync(def)

tempdir = Path.join(getTemp(), String(Math.random()).replace(/0\./, ''))
fs.mkdirSync(tempdir)

config =
	assets: '/'
	cache: tempdir
	cwd: '.'
file = Argv._[0]

plugins = Plugins.load()
pipeline = new Pipeline(config, plugins)
pipeline.compile_file(file, {}, (err) ->
	if err
		rimraf(tempdir, ->)
		return console.warn(err.toString()) if err

	fs.readFile(pipeline.req_to_cache(file), (err, res) ->
		if err
			rimraf(tempdir, ->)
			return console.warn(err.toString()) if err

		console.log(res.toString())
		rimraf(tempdir, ->)
	)
)

