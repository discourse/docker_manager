export default Em.Component.extend({
  classNameBindings: [':logs'],

  render: function(buffer) {
    buffer.push(this.get('output'));
  },

  _outputChanged: function() {
    Em.run.scheduleOnce('afterRender', this, '_scrollBottom');
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

