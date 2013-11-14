$(function(){
  Discourse.MessageBus.start();
  Discourse.MessageBus.subscribe("/docker/log", function(message){
    if(message == "DONE"){
      $("button.upgrade").attr("disabled", false);
    } else {
      $("#log").append($("<pre>" + message + "<pre>"));
    }
  });

  $("button.upgrade").click(function(){
    $("button.upgrade").attr("disabled", true);
    Discourse.ajax({
      url: "/admin/docker/upgrade",
      data: { path: $(this).data("path") },
      dataType: "text",
      method: "POST"
    });
  });

  var ps = function(){
    Discourse.ajax({
      url: "/admin/docker/ps",
      dataType: "text"
    }).then(
      function(data){
        $('#ps').text(data);
      }
    );
  };
  ps();
  setInterval(ps, 5000);

  Discourse.csrfToken = $('meta[name=csrf-token]').attr('content');

  $.ajaxPrefilter(function(options, originalOptions, xhr) {
    if (!options.crossDomain) {
      xhr.setRequestHeader('X-CSRF-Token', Discourse.csrfToken);
    }
  });
});


