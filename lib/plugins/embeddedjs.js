(function() {

  module.exports = {
    source: 'ejs',
    compile: function compile(code, options, callback) {
      var ejs;
      try {
        ejs = require('ejs');
        return callback(null, ejs.render(code));
      } catch (err) {
        return callback(err);
      }
    }
  };

}).call(this);
