
asyncTest "testing jade renderer", ->
	$.get("/tests/03/jade.html", (res) ->
		equal(res, '<div class=\"test\"><p>baz</p></div>')
		start()
	)

