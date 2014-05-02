import ajax from "ic-ajax";

var ProcessList = Em.Object.extend({

  init: function() {
    this._super();
  },

  refresh: function() {
    var self = this;
    return ajax("/admin/docker/ps").then(function(result) {
      self.set('output', result);
      return self;
    });
  }
});

ProcessList.reopenClass({
  find: function() {
    var list = ProcessList.create();
    return list.refresh();
  }
});


export default ProcessList;
