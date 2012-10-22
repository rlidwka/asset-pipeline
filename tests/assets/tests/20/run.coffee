
asyncTest "multiple refs + replace bug", ->
	$.get("/tests/20/multi.html", (res) ->
		equal(res, """
zzzzzzzzzzzzzzzz
/tests/20/test-WglnY2P0.html
123 $&amp; 123 $1 $2 $0

123 $&amp; 123 $1 $2 $0

/tests/20/test-WglnY2P0.html

""")
		start()
	)

