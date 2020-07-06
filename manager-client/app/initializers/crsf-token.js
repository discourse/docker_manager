import Discourse from "manager-client/discourse";

export default {
  name: "findCsrfToken",

  initialize() {
    return Em.$.ajax(Discourse.getAppURL("/session/csrf")).then(result => {
      const token = result.csrf;
      Em.$.ajaxPrefilter((options, originalOptions, xhr) => {
        if (!options.crossDomain) {
          xhr.setRequestHeader("X-CSRF-Token", token);
        }
      });
    });
  }
};
