
asyncTest "inlines includeunsafe", ->
	$.get("/tests/14/includeunsafe.js", (res) ->
		equal(res, """
var y = "this is some unsafe string \\\\\\n\\\\\\\\ \\\\\\\\\\n\\" \\"\\" \\'\\'\\'\\nhi!\\n";

""")
		start()
	)

