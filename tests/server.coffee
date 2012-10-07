#!/usr/bin/env coffee

fs      = require 'fs'
express = require 'express'
path    = require 'path'

app = express()
app.listen(1337, 'localhost')
app.use(express.bodyParser())
app.use require('../index.js')(
	server: app
	extensions: ['.js', '.css', '.html']
	debug: true
	plugin_config:
		'.jade':
			self: true
)
app.set('views', __dirname + '/views')

console.log("it's started! go to http://localhost:1337/ now")

app.get '/', (req, res) -> res.redirect('/tests.html')

app.post('/set', (req, res) ->
	file = path.join('./assets/var/', req.body.file)
	fs.mkdir('./assets/var/', ->
		fs.writeFile(file, req.body.body, ->
			res.send('ok')
		)
	)
)

app.get(/\/view\/(.*)/, (req, res) ->
	res.render(req.params[0])
)

