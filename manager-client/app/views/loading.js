export default Em.View.extend({
  _showOnInsert: function() {
    var self = this;
    self.set('runner', Em.run.later(function() {
      self.$('h3').show();
    }, 200));
  }.on('didInsertElement'),

  _cancelFade: function() {
    Em.run.cancel(this.get('runner'));
  }.on('willDestroyElement')
});

