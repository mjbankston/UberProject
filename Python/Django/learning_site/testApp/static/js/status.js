(function() {
  console.log('Starting status page.');

  // Create a master web socket object from the websocketbridge.js channels library javascript file

  // Use $ -> to ensure document is ready.
  $(function() {
    var webSocketBridge;
    $('#status_div').append($('<p>').append('Test message.'));
    webSocketBridge = new channels.WebSocketBridge();
    webSocketBridge.connect('/ws/');
    // Setup a listener callback function for anything that gets sent on this web socket
    webSocketBridge.listen(function(action, stream) {
      console.log('Received message...', action, stream);
    });
    // Setup a listener callback function for a specific stream channel (called message_stream) 
    // on this web socket
    webSocketBridge.demultiplex('message_stream', function(action, stream) {
      console.info('Received message from message_stream...', action, stream);
    });
    $('#send_message_button').click(function(e) {
      webSocketBridge.send({
        message: "Example message text."
      });
      webSocketBridge.stream('message_stream').send({
        message: "Example streaming text."
      });
    });
  });

}).call(this);


//# sourceMappingURL=status.js.map
//# sourceURL=coffeescript