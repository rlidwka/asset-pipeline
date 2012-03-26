
sleep = (sec = 1) ->
	(cb) ->
		setTimeout(cb, sec*1000)

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

asyncTest "inlines helloworld", ->
	$.get("/inlines/helloworld.js", (res) ->
		equal(res, """
var x = '&quot;&lt;hello &amp; world&gt;&quot;';
var y = '\"<hello & world>\"';
var z = '';

""")
		start()
	)

asyncTest "inline: depend_on", ->
	async.series [
		(cb) ->
			$.post("/set", {file:'depend_on.flag', body:"1"}, (res) ->
				cb()
			)
		,
		(cb) ->
			$.get("/inlines/dependon.js", (res) ->
				cb(null, res)
			)
		,
		sleep(),
		(cb) ->
			$.get("/inlines/dependon.js", (res) ->
				cb(null, res)
			)
		,
		sleep(),
		(cb) ->
			$.post("/set", {file:'depend_on.flag', body:"2"}, (res) ->
				cb()
			)
		,
		(cb) ->
			$.get("/inlines/dependon.js", (res) ->
				cb(null, res)
			)
		,
	], (err, res) ->
		equal(res[1], res[3])
		notEqual(res[3], res[6])
		start()

asyncTest "should not recompile deps for every change", ->
	async.series [
		(cb) ->
			$.post("/set", {file:'recompile.less', body:"h1 {\nwidth:1px;\n}\n@import '../compiletime';\n"}, (res) ->
				cb()
			)
		,
		(cb) ->
			$.get("/var/recompile.css", (res) ->
				cb(null, res)
			)
		,
		sleep(),
		(cb) ->
			$.post("/set", {file:'recompile.less', body:"h1 {\nwidth:1px;\n}\n@import '../compiletime';\n"}, (res) ->
				cb()
			)
		,
		(cb) ->
			$.get("/var/recompile.css", (res) ->
				cb(null, res)
			)
		,
	], (err, res) ->
		equal(res[1], res[4])
		start()

asyncTest "inlines includesimple", ->
	$.get("/inlines/includesimple.js", (res) ->
		equal(res, """
var x = "&lt;div class=&quot;test1&quot;&gt;&lt;/div&gt;";
var y = "&lt;div class=&quot;test2&quot;&gt;&lt;/div&gt;";
var y = "&lt;div class=&quot;test3&quot;&gt;&lt;/div&gt;";
var y = ".test3\\n";

""")
		start()
	)

asyncTest "inlines includeunsafe", ->
	$.get("/inlines/includeunsafe.js", (res) ->
		equal(res, """
var y = "this is some unsafe string \\\\\\n\\\\\\\\ \\\\\\\\\\n\\" \\"\\" \\'\\'\\'\\nhi!\\n";

""")
		start()
	)

asyncTest "inlines - hashes", ->
	$.get("/inlines/hashes.js", (res) ->
		equal(res, """
var x = 'd9c1c3c28592a3856bc07452cc44acd3';
var x = '2cHDwoWS';
var x = 'a91d8cf2ab765ab1cda04a5b3d4a009b';
var x = 'qR2M8qt2';

""")
		start()
	)

asyncTest "inlines - asset_uri", ->
	$.get("/inlines/asset_uri.js", (res) ->
		equal(res, """
var x = '/bin-2cHDwoWS';
var x = '/test-qR2M8qt2.css';
var x = '/tes-kWHwZtAf.coffee';
var x = '/inlines/hel-89eZzvC2.js';

""")
		start()
	)

asyncTest "asset_uri 2 versions", ->
	ver1 = null
	ver2 = null
	async.series [
		(cb) ->
			$.post("/set", {file:'asset_uri.coffee', body:"x = 123\n"}, (res) ->
				cb()
			)
		,
		(cb) ->
			$.get("/inlines/asset_uri_var.js", (res) ->
				ver1 = res
				cb(null, res)
			)
		,
		(cb) ->
			m = ver1.match(/'(.*)'/)
			$.get(m[1], (res) ->
				cb(null, res)
			)
		,
		(cb) ->
			$.get('/var/asset_uri.js', (res) ->
				cb(null, res)
			)
		,
		sleep(),
		(cb) ->
			$.post("/set", {file:'asset_uri.coffee', body:"x = 456\n"}, (res) ->
				cb()
			)
		,
		(cb) ->
			$.get("/inlines/asset_uri_var.js", (res) ->
				ver2 = res
				cb(null, res)
			)
		,
		(cb) ->
			m = ver1.match(/'(.*)'/)
			$.get(m[1], (res) ->
				cb(null, res)
			)
		,
		(cb) ->
			m = ver2.match(/'(.*)'/)
			$.get(m[1], (res) ->
				cb(null, res)
			)
		,
		(cb) ->
			$.get('/var/asset_uri.js', (res) ->
				cb(null, res)
			)
		,
	], (err, res) ->
		start()
		var1 = """
(function() {
  var x;

  x = 123;

}).call(this);

"""
		var2 = """
(function() {
  var x;

  x = 456;

}).call(this);

"""
		equal(res[2], var1)
		equal(res[3], var1)
		equal(res[7], var1)
		equal(res[8], var2)
		equal(res[9], var2)

