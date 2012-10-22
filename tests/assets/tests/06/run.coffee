
asyncTest "testing styl subdirs", ->
	$.get("/tests/06/b/main.css", (res) ->
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

