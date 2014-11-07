import ajax from "ic-ajax";
import Ember from 'ember';

var ProcessList = Ember.Object.extend({

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
