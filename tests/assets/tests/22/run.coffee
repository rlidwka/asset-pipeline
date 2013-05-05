
asyncTest "custom plugin", ->
	$.get("/tests/22/test.js", (res) ->
		equal(res, '''
file = "assets/tests/22/test.js"
base64 = "dGVzdC4uLiB0ZXN0Li4uIHRlc3QuLi4K"

''')
		start()
	)

