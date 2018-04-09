console.log('Starting status page.')

# Use $ -> to ensure document is ready.
$ ->
    $ '#status_div'
    .append(
        $('<p>')
        .append 'Test message.'
    )
