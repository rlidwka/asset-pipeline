
asyncTest "inlines - asset_uri", ->
	$.get("/tests/16/asset_uri.js", (res) ->
		equal(res, """
var x = '/tests/16/bin-2cHDwoWS';
var x = '/tests/16/test-qR2M8qt2.css';
var x = '/tests/16/tes-kWHwZtAf.coffee';
var x = '/tests/16/hel-89eZzvC2.js';

""")
		start()
	)

