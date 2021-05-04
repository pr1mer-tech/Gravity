(function() {
  var WebSocket, stream;

  WebSocket = require('ws');

  stream = new WebSocket('ws://localhost:8081');

  stream.on('open', function() {
    return console.log('connected (use CTRL+C to quit)');
  }).on('message', function(msg) {
    return console.log(msg);
  });

}).call(this);
