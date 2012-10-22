
asyncTest "inlines includesimple", ->
	$.get("/tests/13/includesimple.js", (res) ->
		equal(res, """
var x = "&lt;div class=&quot;test1&quot;&gt;&lt;/div&gt;";
var y = "&lt;div class=&quot;test2&quot;&gt;&lt;/div&gt;";
var y = "&lt;div class=&quot;test3&quot;&gt;&lt;/div&gt;";
var y = ".test3\\n";

""")
		start()
	)

