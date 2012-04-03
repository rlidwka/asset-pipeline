Pipeline = require './pipeline'
Plugins  = require './plugins'

# plugins = {name: {... , require: (lazy require function here)} }
plugins = Plugins.load()

module.exports = asset_pipeline_factory = (config = {}) ->
	pipeline = new Pipeline(config, plugins)
	return pipeline.middleware()
