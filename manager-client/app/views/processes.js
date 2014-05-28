export default Em.View.extend({

  _insertedIntoDOM: function() {
    this.set('controller.autoRefresh', true);
  }.on('didInsertElement'),

  _removedFromDOM: function() {
    this.set('controller.autoRefresh', false);
  }.on('willDestroyElement')

});

