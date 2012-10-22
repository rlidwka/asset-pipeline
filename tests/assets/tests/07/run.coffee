
asyncTest "testing eco + prio", ->
	$.get("/tests/07/test_eco.html", (res) ->
		equal(res, '<div class=\"somediv\">a: 1 b: 2 c: 3 </div>')
		start()
	)

