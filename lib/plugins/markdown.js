(function() {

  module.exports = {
    source: 'md',
    target: 'html',
    compile: function compile(code, options, callback) {
      var md;
      try {
        md = require('node-markdown').Markdown;
        return callback(null, md(code));
      } catch (err) {
        return callback(err);
      }
    }
  };

}).call(this);
