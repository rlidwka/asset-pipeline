
asyncTest "getting .js.coffee.jsx", ->
	$.get("/test3ext.js", (res) ->
		equal(res, '''
(function() {
  var test;

  test = function test() {
    return console.log(2);
  };

}).call(this);

''')
		start()
	)

asyncTest "testing markdown", ->
	$.get("/markdown.html", (res) ->
		equal(res, '''
<h1>oqifoinxeqo</h1>

<p>.test1
    .img</p>
''')
		start()
	)

asyncTest "testing less subdirs", ->
	$.get("/a_less/b/subdirtest_less.css", (res) ->
		equal(res, '''
h1 {
  display: none;
}
h2 {
  display: none;
}
h3 {
  display: none;
  border: 2;
}

''')
		start()
	)

asyncTest "testing styl subdirs", ->
	$.get("/a_styl/b/main.css", (res) ->
		equal(res, '''
h1 {
  display: none;
}
h2 {
  display: none;
}
h3 {
  display: none;
  border: 2;
}

''')
		start()
	)

asyncTest "testing eco + prio", ->
	$.get("/prio_test/test_eco.html", (res) ->
		equal(res, '<div class=\"somediv\">a: 1 b: 2 c: 3 </div>')
		start()
	)

asyncTest "changeable .css - simple", ->
	rand = '1'+Math.random()
	$.post("/set", {file:'test-ch1.less', body:"h1 { width: #{rand}; }"}, (res) ->
		$.get("/var/test-ch1.css", (res) ->
			equal(res, "h1 {\n  width: #{rand};\n}\n")

			setTimeout((->
				rand2 = '2'+Math.random()
				$.post("/set", {file:'test-ch1.less', body:"h1 { width: #{rand2}; }"}, (res) ->
					$.get("/var/test-ch1.css", (res) ->
						equal(res, "h1 {\n  width: #{rand2};\n}\n")
						start()
					)
				)
			), 1000)
		)
	)

asyncTest "require changeable .css", ->
	rand = '1'+Math.random()
	$.post("/set", {file:'test-ch2.less', body:"h1 { width: #{rand}; }"}, (res) ->
		$.get("/test-ch2.css", (res) ->
			equal(res, "h1 {\n  width: #{rand};\n}\nh2 {\n  width: 123;\n}\n")
			rand2 = '2'+Math.random()
			setTimeout((->
				$.post("/set", {file:'test-ch2.less', body:"h1 { width: #{rand2}; }\n\n@import 'test-ch2-2';\n"}, (res) ->
					rand3 = '3'+Math.random()
					$.post("/set", {file:'test-ch2-2.less', body:"h6 { width: #{rand3}; }"}, (res) ->
						$.get("/test-ch2.css", (res) ->
							equal(res, "h1 {\n  width: #{rand2};\n}\nh6 {\n  width: #{rand3};\n}\nh2 {\n  width: 123;\n}\n")
							start()
						)
					)
				)
			), 1000)
		)
	)
