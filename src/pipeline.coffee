fs      = require 'fs'
async   = require 'async'
connect = require 'connect'
Path    = require 'path'

# timestamps are here
cache = {}

# serving_files

plugins = {}

# adds file to the cache
file_found = (path, stats) ->
	ext = Path.extname(path)
	while ext.length > 0
		path = Path.basename(path, ext)
		ext = Path.extname(path)

# this function rescans assets dir and saves timestamp
rescan_file = (path, cb) ->
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
	
pipeline_middleware = (options) ->
	(req, res, next) ->
		next()

module.exports = asset_pipeline_factory = (config = {}) ->
	config.assets ?= './assets'
	config.assets = path.normalize(config.assets)
	config.cache ?= './cache'
	config.cache = path.normalize(config.cache)

	return pipeline_middleware(config)

# load plugins
for filename in fs.readdirSync(__dirname + '/plugins')
	name = filename.substr(0, filename.lastIndexOf('.'))
	plugin = {name}
	plugin.__defineGetter__('require', ->
		return require('./plugins/' + filename)
	)
	plugins[name] = plugin

