(function() {
  var WebSocketServer, wss;

  WebSocketServer = require('ws').Server;

  wss = new WebSocketServer({
    port: 8081
  });

  console.log('websocket server created -> ws://localhost:8081');

  console.log('use CTRL-C to quit');

  wss.on('connection', function(ws) {
    var id, timestamp;
    console.log('connection open (press CTRL+C to quit)');
    timestamp = function() {
      return ws.send(JSON.stringify(new Date()));
    };
    id = setInterval(timestamp, 1000);
    return ws.on('close', function() {
      console.log('connection closed');
      return clearInterval(id);
    });
  });

}).call(this);
