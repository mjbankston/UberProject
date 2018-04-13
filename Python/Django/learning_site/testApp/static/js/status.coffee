console.log('Starting status page.')

# Create a master web socket object from the websocketbridge.js channels library javascript file


# Use $ -> to ensure document is ready.
$ ->
    $('#status_div').append(
        $('<p>').attr('id', 'message_display').append('No message.')
    )

    webSocketBridge = new channels.WebSocketBridge()
    
    webSocketBridge.connect '/ws/'

    # Setup a listener callback function for anything that gets sent on this web socket
    webSocketBridge.listen (msg_ob, stream) ->
        $('#message_display').text(msg_ob.value)

    # Setup a listener callback function for a specific stream channel (called message_stream) 
    # on this web socket
    webSocketBridge.demultiplex 'message_stream', (msg_ob, stream) ->
        console.info 'Received message from message_stream...', msg_ob, stream

    $('#send_message_button').click (e) ->
        webSocketBridge.send(
            message: "Example message text."
        )
        webSocketBridge.stream('message_stream')
            .send(
                message: "Example streaming text."
            )

    ctx = $('#chartjs_canvas')[0].getContext('2d')
    myChart = new Chart(ctx,
        type: 'line'
        data:
            datasets: [
                label: '# of Votes'
                data: [
                    12
                    19
                    3
                    5
                    2
                    3
                ]
                backgroundColor: [
                    'rgba(255, 99, 132, 0.8)'
                    'rgba(54, 162, 235, 0.8)'
                    'rgba(255, 206, 86, 0.8)'
                    'rgba(75, 192, 192, 0.8)'
                    'rgba(153, 102, 255, 0.8)'
                    'rgba(255, 159, 64, 0.8)'
                ]
                borderColor: [
                    'rgba(255,99,132,1)'
                    'rgba(54, 162, 235, 1)'
                    'rgba(255, 206, 86, 1)'
                    'rgba(75, 192, 192, 1)'
                    'rgba(153, 102, 255, 1)'
                    'rgba(255, 159, 64, 1)'
                ]
                borderWidth: 1
            ]
        options: 
            scales: 
                yAxes:
                    ticks: 
                        beginAtZero: true
                xAxes:
                    ticks: 
                        beginAtZero: true
    )
    
    $('#chart_tab_button').click ->
        openTab($('#chart_tab'))

    $('#send_message_tab_button').click ->
        openTab($('#send_message_tab'))

    $('#help_tab_button').click ->
        openTab($('#help_tab'))

openTab = (tab) ->
    $('.tabcontent').each ->
        $(this).hide()
    tab.show()