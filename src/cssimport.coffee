async = require 'async'
Path  = require 'path'
fs    = require 'fs'

found_css_dep = (pipeline, ext, path) ->
	(cb) ->
		pipeline.compile_file(path, (err, res) ->
			return cb(err) if err
			filename = Path.join(pipeline.options.assets,path)
			cachedname = Path.join(pipeline.options.cache,path)
			fs.readFile(cachedname, 'utf8', (err, data) ->
				return cb(err) if err
				scan_code(data, pipeline, ext, filename, cb)
			)
		)

scan_code = (code, pipeline, ext, filename, cb) ->
	ext = '.'+ext.replace(/^\./, '')
	dir = Path.dirname(filename)
	funcs = []
	deplist = []
	matches = code.match(/^@import\s.*$/mg)
	if matches?
		for imports in code.match(/^@import\s.*$/mg)
			file = imports.match(/^@import\s+'([^']+)'/) ? imports.match(/^@import\s+"([^"]+)"/)
			if file
				file = file[1]
				if ext != Path.extname(file)
					file = file + ext
				path = Path.join('/', Path.relative(pipeline.options.assets, Path.join(dir, file)))
				unless path.match(/^\.\.\//)
					deplist.push(path)
					funcs.push(found_css_dep(pipeline, ext, path))
	pipeline.depmgr.depends_on(filename, deplist)
	async.parallel(funcs, (err, res) ->
		if err?.code == 'asset-pipeline/filenotfound'
			cb(new Error("dep not found"))
		else if err
			cb(err)
		else
			if funcs.length > 0
				filename = Path.join(pipeline.options.cache, Path.relative(pipeline.options.assets, filename))
				require('./util').write_file(filename, code, (err) ->
					cb(err, filename)
				)
			else
				cb(null, filename)
	)

module.exports.search_deps = (code, options, ext, cb) ->
	scan_code(code, options.pipeline, ext, options.filename, cb)
