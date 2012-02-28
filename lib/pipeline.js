(function() {
  var Connect, DepMgr, MakePath, Path, Pipeline, URL, async, fs, make_directories, write_file,
    __slice = Array.prototype.slice;

  Path = require('path');

  Connect = require('connect');

  URL = require('url');

  fs = require('fs');

  async = require('async');

  DepMgr = require('./depmgr');

  MakePath = require('./makepath');

  Pipeline = (function() {

    function Pipeline(options, plugins) {
      var file, _base, _base2, _i, _len, _ref, _ref2;
      this.options = options;
      this.plugins = plugins;
      this.files = {};
      this.compile_queue = {};
      if ((_base = this.options).assets == null) _base.assets = './assets';
      this.options.assets = Path.normalize(this.options.assets);
      if ((_base2 = this.options).cache == null) _base2.cache = './cache';
      this.options.cache = Path.normalize(this.options.cache);
      this.builddir = this.options.cache;
      this.depmgr = new DepMgr(this.options.assets);
      this.servers = {
        normal: Connect.static(this.options.cache),
        caching: Connect.static(this.options.cache, {
          maxAge: 365 * 24 * 60 * 60
        })
      };
      _ref2 = (_ref = this.options.files) != null ? _ref : [];
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        file = _ref2[_i];
        this.files[Path.join('/', file)] = {
          nocache: true,
          serve: true
        };
      }
    }

    Pipeline.prototype.middleware = function middleware() {
      var _this = this;
      return function(req, res, next) {
        var file, path, server, url, _ref;
        url = URL.parse(req.url);
        path = decodeURIComponent(url.pathname);
        file = Path.join('/', path);
        if ((_ref = _this.files[file]) != null ? _ref.serve : void 0) {
          server = _this.files[file].nocache ? _this.servers.normal : _this.servers.caching;
          return _this.serve_file(req, res, file, server, next);
        } else {
          return next();
        }
      };
    };

    Pipeline.prototype.serve_file = function serve_file(req, res, file, server, next, safe) {
      var safeNext,
        _this = this;
      if (safe == null) safe = 1;
      safeNext = next;
      if (safe) {
        safeNext = function safeNext(err) {
          if (err) return next(err);
          _this.files[file].compiled = false;
          return _this.serve_file(req, res, file, server, next, 0);
        };
      }
      if (!this.files[file].compiled) {
        return this.compile_file(file, function(err) {
          if (err) return next(err);
          return server(req, res, safeNext);
        });
      } else if (!this.files[file].nocache) {
        return server(req, res, safeNext);
      } else {
        return this.depmgr.check(file, function(err, changed) {
          if (err) return next(err);
          if (changed) {
            _this.files[file].compiled = false;
            return _this.serve_file(req, res, file, server, next);
          } else {
            return server(req, res, safeNext);
          }
        });
      }
    };

    Pipeline.prototype.compile_file = function compile_file(file, cb) {
      var run_callbacks, _base,
        _this = this;
      if ((_base = this.files)[file] == null) _base[file] = file;
      if (this.compile_queue[file] != null) {
        this.compile_queue[file].push(cb);
        return;
      }
      this.compile_queue[file] = [cb];
      run_callbacks = function run_callbacks() {
        var args, old_queue;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        old_queue = _this.compile_queue[file];
        delete _this.compile_queue[file];
        args.unshift(null);
        return async.parallel(old_queue.map(function(f) {
          return f.bind.apply(f, args);
        }));
      };
      return MakePath.find(this.options.assets, file, function(err, found) {
        if (err) return run_callbacks(err);
        return _this.send_to_pipeline(found.path, Path.join(_this.options.cache, file), found.extlist, function(err) {
          if (!err) _this.files[file].compiled = true;
          return run_callbacks(err);
        });
      });
    };

    Pipeline.prototype.actual_pipeline = function actual_pipeline(data, pipes, attrs, cb) {
      var pipe,
        _this = this;
      if (pipes.length === 0) return cb(null, data);
      pipe = pipes.shift();
      if (pipe === '') return actual_pipeline(data, pipes, attrs, cb);
      if (!this.plugins[pipe].compile) return cb(new Error('compiler not found'));
      return this.plugins[pipe].compile(data, attrs, function(err, result) {
        if (err) return cb(err);
        return _this.actual_pipeline(result, pipes, attrs, cb);
      });
    };

    Pipeline.prototype.send_to_pipeline = function send_to_pipeline(file, dest, plugins, cb) {
      var _this = this;
      return fs.readFile(file, 'utf8', function(err, data) {
        if (err) return cb(err);
        return _this.actual_pipeline(data, plugins, {
          filename: file,
          pipeline: _this
        }, function(err, data) {
          if (err) return cb(err);
          return write_file(dest, data, cb);
        });
      });
    };

    return Pipeline;

  })();

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

  write_file = function write_file(dest, data, cb) {
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

  module.exports = Pipeline;

}).call(this);
