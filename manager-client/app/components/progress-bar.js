export default Em.Component.extend({
  classNameBindings: [':progress', ':progress-striped', 'active'],

  active: function() {
    return parseInt(this.get('percent'), 10) !== 100;
  }.property('percent'),

  barStyle: function() {
    var percent = parseInt(this.get('percent'), 10);
    if (percent > 0)  {
      if (percent > 100) { percent = 100; }
      return 'width: ' + this.get('percent') + '%';
    }
  }.property('percent')

});

