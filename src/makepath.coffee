Path = require 'path'
fs   = require 'fs'

mappings = {}

module.exports.setmappings = (map) ->
	mappings = map

module.exports.calc = calc = (from, to, oldpath = [], seen = {}) ->
	return null if oldpath.length > 10 # infinite loop?
	return null if seen[from] # loop
	seen[from] = 1

	#console.log "probing #{to} == #{from}"
	if from == to then return oldpath

	ext = Path.extname(from)
	return null if ext == '' or !mappings[ext]?
	from = Path.basename(from, ext)
	min = Infinity
	minpath = null
	for newext in mappings[ext]
		newpath = oldpath.slice(0).concat(ext)
		res = calc(from+newext, to, newpath, seen)
		if res? and res.length < min
			min = res.length
			minpath = res
	return minpath

# this function scans assets dir for given partial filename
module.exports.find = (path, file, maincb) ->
	search_for = Path.join(path, file)
	base = Path.basename(search_for)
	beginning = base.substr(0, base.indexOf('.')) || base
	fs.readdir(Path.dirname(search_for), (err, files) ->
		maincb(err) if err
		results = []

		found = path:'', extlist:[]
		for foundfile in files when foundfile.indexOf(beginning) == 0
			makepath = calc(foundfile, base)
			if makepath? and found.extlist.length <= makepath.length
				found.path = foundfile
				found.extlist = makepath
		if found.path == ''
			maincb(new Error('File not found'))
		else
			maincb(err, found)
		)
