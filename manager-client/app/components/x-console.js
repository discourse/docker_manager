import Ember from 'ember';

export default Ember.Component.extend({
  classNameBindings: [':logs'],

  _outputChanged: function() {
    Ember.run.scheduleOnce('afterRender', this, '_scrollBottom');
    this.rerender();
  }.observes('output'),

  _scrollBottom: function() {
    if (this.get('followOutput')) {
      this.$().scrollTop(this.$()[0].scrollHeight);
    }
  },

  _scrollOnInsert: function() {
    this._scrollBottom();
  }.on('didInsertElement')
});

