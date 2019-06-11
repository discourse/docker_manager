import Discourse from "manager-client/discourse";

export default {
  name: "message-bus",

  initialize() {
    MessageBus.baseUrl = Discourse.longPollingBaseUrl + "/";

    if (MessageBus.baseUrl !== "/") {
      MessageBus.ajax = function(opts) {
        opts.headers = opts.headers || {};
        opts.headers["X-Shared-Session-Key"] = Em.$(
          "meta[name=shared_session_key]"
        ).attr("content");
        return Em.$.ajax(opts);
      };
    } else {
      MessageBus.baseUrl = Discourse.getURL("/");
    }
  }
};
