(function() {
  var DepsManager;

  DepsManager = (function() {

    function DepsManager(base) {
      this.base = base;
      this.deplist = {};
      this.uselist = {};
    }

    DepsManager.prototype.adddep = function adddep(file, dependon) {
      var _base, _base2;
      if ((_base = this.deplist)[file] == null) _base[file] = {};
      this.deplist[file][dependon] = true;
      if ((_base2 = this.uselist)[dependon] == null) _base2[dependon] = {};
      return this.uselist[dependon][file] = true;
    };

    DepsManager.prototype.check = function check(file, cb) {
      return cb(null, true);
    };

    return DepsManager;

  })();

  module.exports = DepsManager;

}).call(this);
