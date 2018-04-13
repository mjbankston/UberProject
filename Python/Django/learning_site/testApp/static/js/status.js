(function() {
  var openTab;

  console.log('Starting status page.');

  // Create a master web socket object from the websocketbridge.js channels library javascript file

  // Use $ -> to ensure document is ready.
  $(function() {
    var ctx, myChart, webSocketBridge;
    $('#status_div').append($('<p>').attr('id', 'message_display').append('No message.'));
    webSocketBridge = new channels.WebSocketBridge();
    webSocketBridge.connect('/ws/');
    // Setup a listener callback function for anything that gets sent on this web socket
    webSocketBridge.listen(function(msg_ob, stream) {
      return $('#message_display').text(msg_ob.value);
    });
    // Setup a listener callback function for a specific stream channel (called message_stream) 
    // on this web socket
    webSocketBridge.demultiplex('message_stream', function(msg_ob, stream) {
      return console.info('Received message from message_stream...', msg_ob, stream);
    });
    $('#send_message_button').click(function(e) {
      webSocketBridge.send({
        message: "Example message text."
      });
      return webSocketBridge.stream('message_stream').send({
        message: "Example streaming text."
      });
    });
    ctx = $('#chartjs_canvas')[0].getContext('2d');
    myChart = new Chart(ctx, {
      type: 'line',
      data: {
        datasets: [
          {
            label: '# of Votes',
            data: [12,
          19,
          3,
          5,
          2,
          3],
            backgroundColor: ['rgba(255, 99, 132, 0.8)',
          'rgba(54, 162, 235, 0.8)',
          'rgba(255, 206, 86, 0.8)',
          'rgba(75, 192, 192, 0.8)',
          'rgba(153, 102, 255, 0.8)',
          'rgba(255, 159, 64, 0.8)'],
            borderColor: ['rgba(255,99,132,1)',
          'rgba(54, 162, 235, 1)',
          'rgba(255, 206, 86, 1)',
          'rgba(75, 192, 192, 1)',
          'rgba(153, 102, 255, 1)',
          'rgba(255, 159, 64, 1)'],
            borderWidth: 1
          }
        ]
      },
      options: {
        scales: {
          yAxes: {
            ticks: {
              beginAtZero: true
            }
          },
          xAxes: {
            ticks: {
              beginAtZero: true
            }
          }
        }
      }
    });
    $('#information_tab_button').click(function() {
      return openTab($('#information_tab'));
    });
    $('#commands_tab_button').click(function() {
      return openTab($('#commands_tab'));
    });
    return $('#help_tab_button').click(function() {
      return openTab($('#help_tab'));
    });
  });

  openTab = function(tab) {
    $('.tabcontent').each(function() {
      return $(this).hide();
    });
    return tab.show();
  };

}).call(this);


//# sourceMappingURL=status.js.map
//# sourceURL=coffeescript