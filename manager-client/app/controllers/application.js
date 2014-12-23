import Ember from 'ember';

export default Ember.ObjectController.extend({
  showBanner: false,

  actions: {
    dismiss: function () {
      this.set("showBanner", false);
    }
  }
});
