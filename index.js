
var cs_installed = false;
try {
	require('coffee-script');
	cs_installed = true;
} catch(err) {
	module.exports = require('./lib/index');
}

if (cs_installed) module.exports = require('./src/index');

