
asyncTest "tasting bare coffee", ->
	$.get("/subdir/tests/01/test3ext.js", (res) ->
		equal(res.replace(/function test\(\)/, 'function()'), '''
var test;

test = function() {
  return console.log(2);
};

''')
		start()
	)

