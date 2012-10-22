
asyncTest "should not recompile deps for every change", ->
	async.series [
		(cb) ->
			$.post("/set", {file:'recompile.less', body:"h1 {\nwidth:1px;\n}\n@import '../tests/12/compiletime';\n"}, (res) ->
				cb()
			)
		,
		(cb) ->
			$.get("/var/recompile.css", (res) ->
				cb(null, res)
			)
		,
		sleep(),
		(cb) ->
			$.post("/set", {file:'recompile.less', body:"h1 {\nwidth:1px;\n}\n@import '../tests/12/compiletime';\n"}, (res) ->
				cb()
			)
		,
		(cb) ->
			$.get("/var/recompile.css", (res) ->
				cb(null, res)
			)
		,
	], (err, res) ->
		equal(res[1], res[4])
		start()

