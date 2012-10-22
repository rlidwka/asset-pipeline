
asyncTest "require changeable .css", ->
	rand = '1'+Math.random()
	$.post("/set", {file:'test-ch2.less', body:"h1 { width: #{rand}; }"}, (res) ->
		$.get("/tests/09/test-ch2.css", (res) ->
			equal(res, "h1 {\n  width: #{rand};\n}\nh2 {\n  width: 123;\n}\n")
			rand2 = '2'+Math.random()
			setTimeout((->
				$.post("/set", {file:'test-ch2.less', body:"h1 { width: #{rand2}; }\n\n@import 'test-ch2-2';\n"}, (res) ->
					rand3 = '3'+Math.random()
					$.post("/set", {file:'test-ch2-2.less', body:"h6 { width: #{rand3}; }"}, (res) ->
						$.get("/tests/09/test-ch2.css", (res) ->
							equal(res, "h1 {\n  width: #{rand2};\n}\nh6 {\n  width: #{rand3};\n}\nh2 {\n  width: 123;\n}\n")
							start()
						)
					)
				)
			), 1000)
		)
	)

