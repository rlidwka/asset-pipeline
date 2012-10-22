
asyncTest "inlines - same file multiple times", ->
	$.get("/tests/21/samefile.js", (res) ->
		equal(res.match(/hel-89eZzvC2/g).length, 259)
		start()
	)

