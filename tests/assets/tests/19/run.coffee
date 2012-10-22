
asyncTest "views asset_uri 2 versions", ->
	ver1 = null
	ver2 = null
	async.series [
		(cb) ->
			$.post("/set", {file:'asset_uri_d.coffee', body:"x = 123\n"}, (res) ->
				cb()
			)
		,
		(cb) ->
			$.get("/view/19/view_ch.ejs", (res) ->
				ver1 = res
				cb(null, res)
			)
		,
		sleep(),
		(cb) ->
			$.post("/set", {file:'asset_uri_d.coffee', body:"x = 456\n"}, (res) ->
				cb()
			)
		,
		(cb) ->
			$.get("/view/19/view_ch.ejs", (res) ->
				ver2 = res
				cb(null, res)
			)
		,
	], (err, res) ->
		start()
		equal(res[1], "var x = '/var/ass-QTvRUBdR.js';\n")
		equal(res[4], "var x = '/var/ass-m5xcsjyk.js';\n")

