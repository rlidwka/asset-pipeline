async = require 'async'
Path  = require 'path'

module.exports.search_deps = (code, options, ext, cb) ->
	pipeline = options.pipeline
	dir = Path.dirname(options.filename)
	funcs = []
	matches = code.match(/^@import\s.*$/mg)
	if matches?
		for imports in code.match(/^@import\s.*$/mg)
			file = imports.match(/^@import\s+'([^']+)'/) ? imports.match(/^@import\s+"([^"]+)"/)
			if file
				path = Path.relative(pipeline.options.assets, Path.join(dir, file[1]))
				unless path.match(/^\.\.\//)
					funcs.push((cb) -> pipeline.compile_file(Path.join('/', path), cb))
	async.parallel(funcs, cb)
