
try {
	module.exports = require('./src/index');
catch(err) {
	module.exports = require('./lib/index');
}

