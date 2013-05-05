Path = require './path'
fs   = require 'fs'
util = require './util'

module.exports.mappings = mappings = {}

module.exports.calc = calc = (from, to, oldpath = [], seen = {}) ->
	return null if oldpath.length > 10 # infinite loop?
	return null if seen[from] # loop
	seen[from] = 1

	if from == to then return oldpath

	ext = Path.extname(from)
	return null if ext == '' or !mappings[ext]?
	newfrom = Path.basename(from, ext)
	min = Infinity
	minpath = null
	for newext of mappings[ext]
		newpath = oldpath.slice(0).concat({ext, file: newfrom+newext, dst: newext})
		res = calc(newfrom+newext, to, newpath, seen)
		if res? and res.length < min
			min = res.length
			minpath = res
	return minpath

# this function scans assets dir for given partial filename
module.exports.find = (path, file, maincb) ->
	search_for = Path.join(path, file)
	base = Path.basename(search_for)
	beginning = base.substr(0, base.indexOf('.')) || base
	dir = Path.dirname(search_for)
	fs.readdir(dir, (err, files) ->
		return maincb(err) if err
		results = []

		found = path:'', extlist:[]
		for foundfile in files when foundfile.indexOf(beginning) == 0
			makepath = calc(foundfile, base)
			if makepath? and found.extlist.length <= makepath.length
				found.path = Path.join(Path.dirname(search_for),foundfile)
				found.extlist = makepath
				for x in found.extlist
					x.file = Path.join(dir, x.file)
		if found.path == ''
			error = new Error('File not found: ' + file)
			error.code = 'asset-pipeline/filenotfound'
			maincb(error)
		else
			maincb(err, found)
		)
