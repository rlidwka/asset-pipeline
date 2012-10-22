
asyncTest "inlines - hashes", ->
	$.get("/tests/15/hashes.js", (res) ->
		equal(res, """
var x = '2cHDwoWS';
var x = 'qR2M8qt2';

""")
		start()
	)

