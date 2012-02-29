#!/usr/bin/env coffee

express = require 'express'

app = express.createServer()
app.listen(1337)
app.use require('../index.js')(
	extensions: ['.js', '.css', '.html']
)

console.log("it's started! go to http://localhost:1337/ now")

app.get '/', (req, res) -> res.redirect('/tests.html')

