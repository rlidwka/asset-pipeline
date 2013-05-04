# You can compile this using:
# $ node -e 'require("coffee-script");delete require.extensions[".json"];console.log(JSON.stringify(require("./package")));' > package.json

module.exports = {
	# generic info
	name: 'asset-pipeline'
	description: 'Runtime assets builder for Express 3'
	version: '0.2.0'
	author: 'Alex Kocharin <alex@kocharin.ru>'
	dependencies: {
		send: '>= 0.1.0'
		async: '*'
		'async-cache': '*'
		
		# for command-line interface
		# waaay to many things for a simple thing :(
		temporary: '*'
		commander: '*'
		rimraf: '*'
	}

	# all these files needed to run tests
	devDependencies: {
		express: '>= 3'
		'coffee-script': '>= 1.3.3'
		haml: '>= 0.4.3'
		jade: '>= 0.27.2'
		ejs: '>= 0.8.2'
		'node-markdown': '>= 0.1.1'
		less: '>= 1.3.0'
		stylus: '>= 0.29.0'
		eco: '>= 1.1.0-rc-3'
	}

	keywords: 'express assets build coffee jade stylus ejs haml markdown'.split(/\s+/)
	repository: 'git://github.com/rlidwka/asset-pipeline.git'
	main: 'index'
	bin: {
		"asset-pipeline": "./bin/asset-pipeline"
	}

	# potentially could run on 0.4.x, but I don't want to support it
	engines: { node: '>= 0.6.0' }
}

