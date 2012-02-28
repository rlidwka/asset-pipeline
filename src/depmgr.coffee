
class DepsManager
	constructor: (@base) ->
		@deplist = {}
		@uselist = {}
	
	adddep: (file, dependon) ->
		@deplist[file] ?= {}
		@deplist[file][dependon] = true
		@uselist[dependon] ?= {}
		@uselist[dependon][file] = true

module.exports = DepsManager

