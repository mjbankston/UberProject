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
        $('#message_display').html('<b>' + msg_ob.value + '</b>')
        return

    # Setup a listener callback function for a specific stream channel (called message_stream) 
    # on this web socket
    webSocketBridge.demultiplex 'message_stream', (msg_ob, stream) ->
        console.info 'Received message from message_stream...', msg_ob, stream
        return

    $('#send_message_button').click (e) ->
        webSocketBridge.send(
            message: "Example message text."
        )
        webSocketBridge.stream('message_stream')
            .send(
                message: "Example streaming text."
            )
        return

    return