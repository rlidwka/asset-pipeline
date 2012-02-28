(function() {
  var MakePath, Path, Pipeline, asset_pipeline_factory, fs, load_plugins, plugins;

  fs = require('fs');

  Path = require('path');

  Pipeline = require('./pipeline');

  MakePath = require('./makepath');

  plugins = {};

  module.exports = asset_pipeline_factory = function asset_pipeline_factory(config) {
    var pipeline;
    if (config == null) config = {};
    pipeline = new Pipeline(config, plugins);
    return pipeline.middleware();
  };

  load_plugins = function load_plugins() {
    var ext, filename, mappings, name, plugin, te, _i, _j, _k, _len, _len2, _len3, _ref, _ref2, _ref3;
    mappings = {};
    _ref = fs.readdirSync(__dirname + '/plugins');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      filename = _ref[_i];
      name = Path.basename(filename, Path.extname(filename));
      try {
        plugin = require('./plugins/' + filename);
        if (plugin.compile) {
          if (typeof plugin.source === 'string') plugin.source = [plugin.source];
          if (typeof plugin.target === 'string') plugin.target = [plugin.target];
          if (plugin.source) {
            _ref2 = plugin.source;
            for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
              ext = _ref2[_j];
              plugins['.' + ext] = plugin;
              mappings['.' + ext] = [''];
              if (plugin.target != null) {
                _ref3 = plugin.target;
                for (_k = 0, _len3 = _ref3.length; _k < _len3; _k++) {
                  te = _ref3[_k];
                  mappings['.' + ext].push('.' + te.replace(/^\./g, ''));
                }
              }
            }
          }
        }
      } catch (err) {

      }
    }
    return MakePath.setmappings(mappings);
  };

  load_plugins();

}).call(this);
