console.log('Starting status page.')

# Create a master web socket object from the websocketbridge.js channels library javascript file


# Use $ -> to ensure document is ready.
$ ->
    $('#status_div').append(
        $('<p>').append('Test message.')
    )

    webSocketBridge = new channels.WebSocketBridge()
    
    webSocketBridge.connect '/ws/'

    # Setup a listener callback function for anything that gets sent on this web socket
    webSocketBridge.listen (action, stream) ->
        console.log 'Received message...', action, stream
        return

    # Setup a listener callback function for a specific stream channel (called message_stream) 
    # on this web socket
    webSocketBridge.demultiplex 'message_stream', (action, stream) ->
        console.info 'Received message from message_stream...', action, stream
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