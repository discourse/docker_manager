export default Em.Component.extend({
  classNameBindings: [':progress'],

  barStyle: function() {
    var percent = parseInt(this.get('percent'), 10);
    if (percent > 0)  {
      if (percent > 100) { percent = 100; }
      return 'width: ' + this.get('percent') + '%';
    }
  }.property('percent')

});

