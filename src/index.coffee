fs       = require 'fs'
Path     = require './path'
Pipeline = require './pipeline'
MakePath = require './makepath'

# plugins = {name: {... , require: (lazy require function here)} }
#mappings = {}

module.exports = asset_pipeline_factory = (config = {}) ->
	pipeline = new Pipeline(config, MakePath.mappings)
	result = pipeline.middleware()
	result.inlines = pipeline.inlines
	result.get_file = -> pipeline.get_file(arguments...)
	return result

load_plugins = ->
	# source extension -> target extension
	for filename in fs.readdirSync(__dirname + '/plugins')
		#name = Path.basename(filename, Path.extname(filename))
		try
			plugin = require('./plugins/' + filename)
			ok = true
		catch err
			console.error(err)
		if ok && plugin.compile? && plugin.source?
			module.exports.register_plugin plugin

module.exports.register_plugin = ({source, target, compile}) ->
	source = [source] if typeof(source) == 'string'
	target = [target] if typeof(target) == 'string'
	for ext in source
		MakePath.mappings['.'+ext] ?= {}
		MakePath.mappings['.'+ext][''] = compile
		if target?
			for te in target
				MakePath.mappings['.'+ext]['.'+te.replace(/^\./g, '')] = compile

load_plugins()

