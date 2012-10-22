
asyncTest "views - asset_uri", ->
	$.get("/view/18/view_asset_uri.ejs", (res) ->
		equal(res, """
var x = '/tests/18/bin-2cHDwoWS';
var x = '/tests/18/bin-2cHDwoWS';

var x = '/tests/18/test-qR2M8qt2.css';
var x = '/tests/18/tes-kWHwZtAf.coffee';
var x = '/tests/18/dir/hel-89eZzvC2.js';

""")
		start()
	)

