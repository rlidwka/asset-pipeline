
asyncTest "testing less subdirs", ->
	$.get("/tests/05/b/subdirtest_less.css", (res) ->
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

