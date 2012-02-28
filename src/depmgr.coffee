
class DepsManager
	constructor: (@base) ->
		@deplist = {}
		@uselist = {}
	
	adddep: (file, dependon) ->
		@deplist[file] ?= {}
		@deplist[file][dependon] = true
		@uselist[dependon] ?= {}
		@uselist[dependon][file] = true

	check: (file, cb) ->
		return cb(null, true)

module.exports = DepsManager

