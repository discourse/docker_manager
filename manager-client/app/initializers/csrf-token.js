import ajax from "ic-ajax";

export default {
  name: "findCsrfToken",

  initialize: function(container, application) {
    return ajax('/session/csrf').then(function(result) {
      var token = result.csrf;
      $.ajaxPrefilter(function(options, originalOptions, xhr) {
        if (!options.crossDomain) {
          xhr.setRequestHeader('X-CSRF-Token', token);
        }
      });
    });
  }
};
