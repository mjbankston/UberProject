(function() {
  console.log('Starting status page.');

  // Use $ -> to ensure document is ready.
  $(function() {
    return $('#status_div').append($('<p>').append('Test message.'));
  });

}).call(this);


//# sourceMappingURL=status.js.map
//# sourceURL=coffeescript