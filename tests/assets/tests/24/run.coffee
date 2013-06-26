
asyncTest "inlines - asset_uri in subdir", ->
	$.get("/subdir/tests/24/asset_uri.js", (res) ->
		equal(res, """
var x = '/subdir/tests/24/bin-2cHDwoWS';
var x = '/subdir/tests/24/test-qR2M8qt2.css';
var x = '/subdir/tests/24/tes-kWHwZtAf.coffee';
var x = '/subdir/tests/24/hel-89eZzvC2.js';

""")
		start()
	)

