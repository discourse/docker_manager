import Discourse from "manager-client/discourse";
import jQuery from "jquery";

export default {
  name: "findCsrfToken",

  initialize() {
    return jQuery.ajax(Discourse.getAppURL("/session/csrf")).then((result) => {
      const token = result.csrf;
      jQuery.ajaxPrefilter((options, originalOptions, xhr) => {
        if (!options.crossDomain) {
          xhr.setRequestHeader("X-CSRF-Token", token);
        }
      });
    });
  },
};
