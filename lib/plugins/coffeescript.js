(function() {

  module.exports = {
    source: 'coffee',
    target: 'js',
    compile: function compile(code, options, callback) {
      var coffee;
      try {
        coffee = require('coffee-script');
        return callback(null, coffee.compile(code, {
          filename: options.filename
        }));
      } catch (err) {
        return callback(err);
      }
    }
  };

}).call(this);
