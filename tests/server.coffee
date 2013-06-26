#!/usr/bin/env coffee

fs      = require 'fs'
express = require 'express'
path    = require 'path'

app = express()
app.listen(1337, 'localhost')
app.use(express.bodyParser())

pipeline = require('../index.js')
pipeline.register_plugin {
	source: 'base64'
	compile: (code, options, callback) ->
		callback(null, "file = \"#{options.filename}\"\nbase64 = \"#{new Buffer(code).toString('base64')}\"\n")
}

app.use pipeline(
	server: app
	extensions: ['.js', '.css', '.html']
	debug: true
	plugin_config:
		'.jade':
			self: true
)
app.use('/subdir', pipeline(
	server: app
	extensions: ['.js', '.css', '.html']
	mount_point: '/subdir'
	cache: 'cache/subdir'
	debug: true
	plugin_config:
		'.coffee':
			bare: true
))
app.set('views', __dirname + '/assets/tests')

console.log("it's started! go to http://localhost:1337/ now")

app.get '/', (req, res) -> res.redirect('/tests.html')

# API to set an arbitrary file on server
# WARNING: it is dangerous, do not give an access to this to anybody you don't trust
app.post('/set', (req, res) ->
	file = path.join('./assets/var/', req.body.file)
	fs.mkdir('./assets/var/', ->
		fs.writeFile(file, req.body.body, ->
			res.send('ok')
		)
	)
)

# API to	render a custom view for tests
app.get(/\/view\/(.*)/, (req, res) ->
	res.render(req.params[0])
)

