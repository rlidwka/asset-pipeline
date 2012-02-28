fs       = require 'fs'
Path     = require 'path'
Pipeline = require './pipeline'
MakePath = require './makepath'

# plugins = {name: {... , require: (lazy require function here)} }
plugins = {}

module.exports = asset_pipeline_factory = (config = {}) ->
	pipeline = new Pipeline(config, plugins)
	return pipeline.middleware()

load_plugins = ->
	# source extension -> target extension
	mappings = {}

	for filename in fs.readdirSync(__dirname + '/plugins')
		name = Path.basename(filename, Path.extname(filename))
		try
			plugin = require('./plugins/' + filename)
			if plugin.compile
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
	MakePath.setmappings(mappings)

load_plugins()
