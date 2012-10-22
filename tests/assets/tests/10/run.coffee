
asyncTest "inlines helloworld", ->
	$.get("/tests/10/helloworld.js", (res) ->
		equal(res, """
var x = '&quot;&lt;hello &amp; world&gt;&quot;';
var y = '\"<hello & world>\"';
var z = '';

""")
		start()
	)

