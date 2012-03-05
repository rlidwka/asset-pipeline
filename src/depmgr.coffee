util = require './util'

class DepsManager
	constructor: (@base) ->
		@resolving = {}
		@deplist = {}
		@uselist = {}
	
	adddep: (file, dependon) ->
		util.log "file #{file} depends on #{dependon}"
		@deplist[file] ?= {}
		@deplist[file][dependon] = true
		@uselist[dependon] ?= {}
		@uselist[dependon][file] = true

	resolves_to: (file, path)
		unless path?
			util.log "file #{file} is not resolved"
			delete @resolving[file]
			return
		util.log "file #{file} is resolved into #{path}"
		@resolving[file] = path

	check: (file, cb) ->
		return cb(null, false)

module.exports = DepsManager

