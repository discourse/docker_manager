/* global Discourse */

import request from 'ember-ajax/request';
import Ember from 'ember';

var ProcessList = Ember.Object.extend({

  init() {
    this._super();
  },

  refresh() {
    return request(Discourse.getURL("/admin/docker/ps"), {dataType: 'text'}).then(result => {
      this.set('output', result);
    });
  }
});

ProcessList.reopenClass({
  find() {
    const list = ProcessList.create();
    return list.refresh();
  }
});


export default ProcessList;
