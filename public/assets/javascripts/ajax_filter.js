// Generated by CoffeeScript 1.9.3
(function() {
  var attribute, initialize;

  attribute = 'data-ajax-filters';

  initialize = function(node, target) {
    var inputs, nodes;
    inputs = $('select, input', node);
    console.log(inputs);
    nodes = $(inputs);
    return nodes.change(function(event) {
      var query, url;
      query = $(node).serialize();
      url = window.location.pathname + '?' + query;
      NProgress.start();
      return $.ajax(url, {
        success: function(data) {
          $(target).html(data);
          return NProgress.done();
        }
      });
    });
  };

  $("*[" + attribute + "]").each(function(index, element) {
    var value;
    value = $($(element).attr(attribute));
    return initialize(element, value);
  });

}).call(this);