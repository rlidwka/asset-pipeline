(function() {
  var Path, calc, fs, mappings;

  Path = require('path');

  fs = require('fs');

  mappings = {};

  module.exports.setmappings = function setmappings(map) {
    return mappings = map;
  };

  module.exports.calc = calc = function calc(from, to, oldpath, seen) {
    var ext, min, minpath, newext, newpath, res, _i, _len, _ref;
    if (oldpath == null) oldpath = [];
    if (seen == null) seen = {};
    if (oldpath.length > 10) return null;
    if (seen[from]) return null;
    seen[from] = 1;
    if (from === to) return oldpath;
    ext = Path.extname(from);
    if (ext === '' || !(mappings[ext] != null)) return null;
    from = Path.basename(from, ext);
    min = Infinity;
    minpath = null;
    _ref = mappings[ext];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      newext = _ref[_i];
      newpath = oldpath.slice(0).concat(ext);
      res = calc(from + newext, to, newpath, seen);
      if ((res != null) && res.length < min) {
        min = res.length;
        minpath = res;
      }
    }
    return minpath;
  };

  module.exports.find = function find(path, file, maincb) {
    var base, beginning, search_for;
    search_for = Path.join(path, file);
    base = Path.basename(search_for);
    beginning = base.substr(0, base.indexOf('.')) || base;
    return fs.readdir(Path.dirname(search_for), function(err, files) {
      var found, foundfile, makepath, results, _i, _len;
      if (err) maincb(err);
      results = [];
      found = {
        path: '',
        extlist: []
      };
      for (_i = 0, _len = files.length; _i < _len; _i++) {
        foundfile = files[_i];
        if (!(foundfile.indexOf(beginning) === 0)) continue;
        makepath = calc(foundfile, base);
        if ((makepath != null) && found.extlist.length <= makepath.length) {
          found.path = Path.join(Path.dirname(search_for), foundfile);
          found.extlist = makepath;
        }
      }
      if (found.path === '') {
        return maincb(new Error('File not found'));
      } else {
        return maincb(err, found);
      }
    });
  };

}).call(this);
