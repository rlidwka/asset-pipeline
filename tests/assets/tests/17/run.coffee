
asyncTest "inlines asset_uri 2 versions", ->
	ver1 = null
	ver2 = null
	async.series [
		(cb) ->
			$.post("/set", {file:'asset_uri.coffee', body:"x = 123\n"}, (res) ->
				cb()
			)
		,
		(cb) ->
			$.get("/tests/17/asset_uri_var.js", (res) ->
				ver1 = res
				cb(null, res)
			)
		,
		(cb) ->
			m = ver1.match(/'(.*)'/)
			$.get(m[1], (res) ->
				cb(null, res)
			)
		,
		(cb) ->
			$.get('/var/asset_uri.js', (res) ->
				cb(null, res)
			)
		,
		sleep(),
		(cb) ->
			$.post("/set", {file:'asset_uri.coffee', body:"x = 456\n"}, (res) ->
				cb()
			)
		,
		(cb) ->
			$.get("/tests/17/asset_uri_var.js", (res) ->
				ver2 = res
				cb(null, res)
			)
		,
		(cb) ->
			m = ver1.match(/'(.*)'/)
			$.get(m[1], (res) ->
				cb(null, res)
			)
		,
		(cb) ->
			m = ver2.match(/'(.*)'/)
			$.get(m[1], (res) ->
				cb(null, res)
			)
		,
		(cb) ->
			$.get('/var/asset_uri.js', (res) ->
				cb(null, res)
			)
		,
	], (err, res) ->
		start()
		var1 = """
(function() {
  var x;

  x = 123;

}).call(this);

"""
		var2 = """
(function() {
  var x;

  x = 456;

}).call(this);

"""
		equal(res[2], var1)
		equal(res[3], var1)
		equal(res[7], var1)
		equal(res[8], var2)
		equal(res[9], var2)

