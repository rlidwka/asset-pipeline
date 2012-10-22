
asyncTest "inline: depend_on", ->
	async.series [
		(cb) ->
			$.post("/set", {file:'depend_on.flag', body:"1"}, (res) ->
				cb()
			)
		,
		(cb) ->
			$.get("/tests/11/dependon.js", (res) ->
				cb(null, res)
			)
		,
		sleep(),
		(cb) ->
			$.get("/tests/11/dependon.js", (res) ->
				cb(null, res)
			)
		,
		sleep(),
		(cb) ->
			$.post("/set", {file:'depend_on.flag', body:"2"}, (res) ->
				cb()
			)
		,
		(cb) ->
			$.get("/tests/11/dependon.js", (res) ->
				cb(null, res)
			)
		,
	], (err, res) ->
		equal(res[1], res[3])
		notEqual(res[3], res[6])
		start()

