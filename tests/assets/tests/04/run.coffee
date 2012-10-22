
asyncTest "testing jade compiler", ->
	$.get("/tests/04/jade.js", (res) ->
		equal(res, '''
function anonymous(locals, attrs, escape, rethrow, merge) {
attrs = attrs || jade.attrs; escape = escape || jade.escape; rethrow = rethrow || jade.rethrow; merge = merge || jade.merge;
var buf = [];
var self = locals || {};
var interp;
buf.push('<div class="test">');
if ( typeof(foo) != 'undefined')
{
buf.push('<p>');
var __val__ = foo
buf.push(escape(null == __val__ ? "" : __val__));
buf.push('</p>');
}
else
{
buf.push('<p>baz</p>');
}
buf.push('</div>');return buf.join(\"\");
}
''')
		start()
	)

