/* global MessageBus, Discourse, $:true */

export default {
  name: "message-bus",

  initialize() {
    MessageBus.baseUrl = Discourse.longPollingBaseUrl;

    if (MessageBus.baseUrl !== '/') {
      MessageBus.ajax = function(opts) {
        opts.headers = opts.headers || {};
        opts.headers['X-Shared-Session-Key'] = $('meta[name=shared_session_key]').attr('content');
        return $.ajax(opts);
      };
    } else {
      MessageBus.baseUrl = Discourse.getURL('/');
    }
  }
};
