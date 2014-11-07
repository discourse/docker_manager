/* global moment:true */
import Ember from 'ember';

export default Ember.Handlebars.makeBoundHelper(function(dt) {
  if (Ember.isEmpty(dt)) {
    return new Ember.Handlebars.SafeString("&mdash;");
  }

  return moment(dt).fromNow();
});
