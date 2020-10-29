import Discourse from "manager-client/discourse";
import jQuery from "jquery";

export default {
  name: "message-bus",

  initialize() {
    MessageBus.baseUrl = Discourse.longPollingBaseUrl.replace(/\/$/, "") + "/";

    if (MessageBus.baseUrl !== "/") {
      MessageBus.ajax = function (opts) {
        opts.headers = opts.headers || {};
        const meta = document.querySelector("meta[name=shared_session_key]");
        if (meta) {
          opts.headers["X-Shared-Session-Key"] = meta.content;
        }
        return jQuery.ajax(opts);
      };
    } else {
      MessageBus.baseUrl = Discourse.getAppURL("/");
    }
  },
};
