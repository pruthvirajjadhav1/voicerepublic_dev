/*
 * CREATE NOTICE
 */

(function($){


	var helpNotices = {};

  helpNotices.build = function() {
    helpNotices.onPage = $('.help-text');

    function closeBox() {
      var closeIt = $('<div />').addClass('alert alert-info').html('<a href="#">Hilfe schließen</a>');
      closeIt.appendTo('#flash_messages');
      closeIt.children('a').on('click', function(e){
        e.preventDefault();
        helpNotices.onPage.fadeOut('fast', function() {
          helpNotices.onPage.remove();
        });
        closeIt.fadeOut('fast', function() {
          closeIt.remove();
        });
      });
    }

    var parent;
    $.each(helpNotices.onPage, function() {
      parent = $(this).parent();
      if (parent.css("position") === "static") {
        parent.css("position", "relative");
      }
    });
    closeBox();
  };

  helpNotices.init = function() {
    helpNotices.onPage = $('.help-text');
    if (helpNotices.onPage.length > 0){
      helpNotices.build();
    }
  };

	// document.ready
	$(function(){

		helpNotices.init();
	});
})(jQuery);