
asyncTest "getting .js.coffee.jsx", ->
	$.get("/tests/01/test3ext.js", (res) ->
		equal(res.replace(/function test\(\)/, 'function()'), '''
(function() {
  var test;

  test = function() {
    return console.log(2);
  };

}).call(this);

''')
		start()
	)

