/* global $:true, Discourse */
import request from 'ember-ajax/request';

export default {
  name: "findCsrfToken",

  initialize() {
    return request(Discourse.getURL('/session/csrf')).then(function(result) {
      var token = result.csrf;
      $.ajaxPrefilter(function(options, originalOptions, xhr) {
        if (!options.crossDomain) {
          xhr.setRequestHeader('X-CSRF-Token', token);
        }
      });
    });
  }
};
