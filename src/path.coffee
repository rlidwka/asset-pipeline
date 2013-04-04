# unix-style path wrapper for windows

Path = require('path')

dewindoze = (fn) -> ->
	fn(arguments...).replace(/^[A-Z]:\\/, '\\').replace(/\\/g, '/')

if require('os').platform() != 'win32'
	module.exports = Path
else
	for func in ['basename', 'dirname', 'extname', 'join', 'normalize', 'relative', 'resolve']
		module.exports[func] = dewindoze(Path[func])

