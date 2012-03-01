
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
		console.log arguments
		equal(res, '''
<h1>oqifoinxeqo</h1>

<p>.test1
    .img</p>
''')
		start()
	)

asyncTest "testing less subdirs", ->
	$.get("/a_less/b/subdirtest_less.css", (res) ->
		console.log arguments
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
		console.log arguments
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
