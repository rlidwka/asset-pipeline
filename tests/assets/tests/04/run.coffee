
asyncTest "testing jade compiler", ->
	$.get("/tests/04/jade.js", (res) ->
		equal(res, '''
function anonymous(locals) {
var buf = [];
var self = locals || {};
buf.push(\"<div class=\\"test\\">\");
if ( typeof(foo) != 'undefined')
{
buf.push(\"<p>\" + (jade.escape(null == (jade.interp = foo) ? \"\" : jade.interp)) + \"</p>\");
}
else
{
buf.push(\"<p>baz</p>\");
}
buf.push(\"</div>\");;return buf.join(\"\");
}
''')
		start()
	)

