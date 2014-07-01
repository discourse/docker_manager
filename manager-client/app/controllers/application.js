export default Em.ObjectController.extend({
  showBanner: false,

  actions: {
    dismiss: function () {
      this.set("showBanner", false);
    }
  }
});
