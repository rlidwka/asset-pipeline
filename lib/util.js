// Generated by CoffeeScript 1.2.1-pre
(function() {
  var Path, exports, fs, make_directories, util, _do_log,
    __slice = [].slice;

  Path = require('path');

  fs = require('fs');

  util = require('util');

  _do_log = false;

  exports = module.exports = {};

  make_directories = function make_directories(dest, cb) {
    var dir;
    dir = Path.dirname(dest);
    if (dir === '.' || dir === '..') return cb();
    return fs.mkdir(dir, function(err) {
      if ((err != null ? err.code : void 0) === 'ENOENT') {
        return make_directories(dir, function() {
          return fs.mkdir(dir, cb);
        });
      } else {
        return cb();
      }
    });
  };

  exports.write_file = function write_file(dest, data, cb) {
    return fs.writeFile(dest, data, function(err) {
      if ((err != null ? err.code : void 0) === 'ENOENT') {
        return make_directories(dest, function() {
          return fs.writeFile(dest, data, cb);
        });
      } else {
        return cb(err);
      }
    });
  };

  exports.do_log = function do_log(arg) {
    if (arg != null) _do_log = !!arg;
    return _do_log;
  };

  exports.log = function log() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    if (_do_log) return util.log.apply(util, args);
  };

}).call(this);