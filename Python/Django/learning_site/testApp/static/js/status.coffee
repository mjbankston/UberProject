console.log('Starting status page.')

# Create a master web socket object from the websocketbridge.js channels library javascript file


# Use $ -> to ensure document is ready.
$ ->
    $('#status_div').append(
        $('<p>').attr('id', 'message_display').append('No message.')
    )

    Chart.defaults.line.tension = 0
    Chart.defaults.line.fill = false
    Chart.defaults.line.cubicInterpolationMode = 'monotone'
    # signal_real_context = $('#signal_real_chartjs_canvas')[0].getContext('2d')
    # signal_real_chart = new Chart(signal_real_context,
    #     type: 'line'
    #     data:
    #         datasets: [
    #             label: 'Signal (real)'
    #             data: [
    #             ]
    #             borderColor: [
    #                 'rgba(0, 50, 255, 1)'
    #             ]
    #             borderWidth: 1
    #             pointRadius: 0
    #         ]
    #     options:
    #         scales: 
    #             yAxes:
    #                 ticks:
    #                     min: -1.0
    #                     max: 1.0
    #         elements:
    #             line:
    #                 tension: 0
    #                 cubicInterpolationMode: 'monotone'
    #                 fill: false
    #         animation:
    #             duration: 0
    #         hover:
    #             animationDuration: 0
    #         responsiveAnimationDuration: 0
    # )

    # signal_imag_context = $('#signal_imag_chartjs_canvas')[0].getContext('2d')
    # signal_imag_chart = new Chart(signal_imag_context,
    #     type: 'line'
    #     data:
    #         datasets: [
    #             label: 'Signal (imag)'
    #             data: [
    #             ]
    #             borderColor: [
    #                 'rgba(0, 128, 50, 1)'
    #             ]
    #             borderWidth: 1
    #             pointRadius: 0
    #         ]
    #     options:
    #         scales: 
    #             yAxes:
    #                 ticks:
    #                     min: -1.0
    #                     max: 1.0
    #         elements:
    #             line:
    #                 tension: 0
    #                 cubicInterpolationMode: 'monotone'
    #                 fill: false
    #         animation:
    #             duration: 0
    #         hover:
    #             animationDuration: 0
    #         responsiveAnimationDuration: 0
    # )

    signal_psd_context = $('#psd_chartjs_canvas')[0].getContext('2d')
    signal_psd_chart = new Chart(signal_psd_context,
        type: 'line'
        data:
            datasets: [
                label: 'Power Spectral Density'
                data: [
                ]
                borderColor: [
                    'rgba(128, 128, 0, 1)'
                ]
                borderWidth: 1
                pointRadius: 0
            ]
        options:
            scales: 
                yAxes:
                    ticks:
                        min: -1.0
                        max: 1.0
                xAxes:
                    ticks:
                        min: -0.5
                        max: 0.5
            elements:
                line:
                    tension: 0
                    cubicInterpolationMode: 'monotone'
                    fill: false
            animation:
                duration: 0
            hover:
                animationDuration: 0
            responsiveAnimationDuration: 0
    )

    webSocketBridge = new channels.WebSocketBridge()
    
    webSocketBridge.connect '/ws/'

    waveformGraphLock = false
    psdGraphLock = false
    # Setup a listener callback function for anything that gets sent on this web socket
    webSocketBridge.listen (msg_ob, stream) ->
        if msg_ob.type == "signal" and waveformGraphLock is false
            waveformGraphLock = true
            real_labels = []
            for n, i in msg_ob.real
                real_labels.push(i)
            signal_real_chart.data.labels = real_labels
            signal_real_chart.data.datasets.forEach (dataset) ->
                dataset.data = msg_ob.real
            signal_real_chart.update()
            imag_labels = []
            for n, i in msg_ob.imag
                imag_labels.push(i)
            signal_imag_chart.data.labels = imag_labels
            signal_imag_chart.data.datasets.forEach (dataset) ->
                dataset.data = msg_ob.imag
            signal_imag_chart.update()
            waveformGraphLock = false
        else if msg_ob.type == "psd" and psdGraphLock is false
            psdGraphLock = true
            psd_freq = []
            psd_power = []
            for e in msg_ob.psd
                psd_freq.push(e['x'])
                psd_power.push(e['y'])
            signal_psd_chart.data.labels = psd_freq
            signal_psd_chart.data.datasets.forEach (dataset) ->
                dataset.data = psd_power
            signal_psd_chart.update()
            psdGraphLock = false
        else if msg_ob.type == "message_text"
            $('#message_display').text(msg_ob.text)

    # Setup a listener callback function for a specific stream channel (called message_stream) 
    # on this web socket
    webSocketBridge.demultiplex 'message_stream', (msg_ob, stream) ->
        console.info 'Received message from message_stream...', msg_ob, stream

    $('#send_command_button').click (e) ->
        webSocketBridge.send(
            sender: 'command_button'
            message: "Example command message."
        )
    
    $('#information_tab_button').click ->
        openTab($('#information_tab'))

    $('#commands_tab_button').click ->
        openTab($('#commands_tab'))

    $('#help_tab_button').click ->
        openTab($('#help_tab'))

openTab = (tab) ->
    $('.tabcontent').each ->
        $(this).hide()
    tab.show()