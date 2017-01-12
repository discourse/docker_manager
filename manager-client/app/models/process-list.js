/* global Discourse */

import request from 'ember-ajax/request';
import Ember from 'ember';

const ProcessList = Ember.Object.extend({
  output: null,

  refresh() {
    return request(Discourse.getURL("/admin/docker/ps"), {dataType: 'text'}).then(result => {
      this.set('output', result);
      return this;
    });
  }
});

export function find() {
  return ProcessList.create().refresh();
}

export default ProcessList;
