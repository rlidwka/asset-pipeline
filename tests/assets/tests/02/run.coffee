
asyncTest "testing markdown", ->
	$.get("/tests/02/markdown.html", (res) ->
		equal(res, '''
<h1>oqifoinxeqo</h1>

<p>.test1
    .img</p>
''')
		start()
	)

