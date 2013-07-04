
module.exports = (names, options) ->
	_names = names
	if typeof(names) == 'string'
		names = [names]

	for name in names
		if options.dependencies?[name]?
			return options.dependencies[name]

	for name in names
		try
			return require name
		catch err

	throw new Error("could not find module #{_names}");

