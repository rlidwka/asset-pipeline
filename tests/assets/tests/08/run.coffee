
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

