async = require 'async'
Path  = require './path'
fs    = require 'fs'

found_css_dep = (orig, ext, path) ->
	(cb) =>
		@pipeline.compile_file(path, (err, res) =>
			return cb(err) if err
			@pipeline.depmgr.depends_on(@pipeline.path_to_req(orig), path)
			filename = @pipeline.path_to_req(path)
			cachedname = @pipeline.req_to_cache(filename)
			fs.readFile(cachedname, 'utf8', (err, data) =>
				return cb(err) if err
				scan_code.call(@, data, ext, filename, cb)
			)
		)

scan_code = (code, ext, filename, cb) ->
	ext = '.'+ext.replace(/^\./, '')
	dir = Path.dirname(filename)
	funcs = []
	matches = code.match(/^@import\s.*$/mg)
	if matches?
		for imports in code.match(/^@import\s.*$/mg)
			file = imports.match(/^@import\s+'([^']+)'/) ? imports.match(/^@import\s+"([^"]+)"/)
			if file
				file = file[1]
				if ext != Path.extname(file)
					file = file + ext
				path = @pipeline.path_to_req(Path.join(dir, file))
				unless path.match(/^\.\.\//)
					funcs.push(found_css_dep.call(@, filename, ext, path))
	async.parallel(funcs, (err, res) =>
		if err
			cb(err)
		else
			if funcs.length > 0
				filename = @pipeline.path_to_cache(filename)
				require('./util').write_file(filename, code, (err) =>
					cb(err, filename)
				)
			else
				cb(null, filename)
	)

module.exports.search_deps = (code, options, ext, cb) ->
	scan_code.call(options, code, ext, options.filename, cb)
