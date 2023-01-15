import Controller from "@ember/controller";

export default Controller.extend({
  autoRefresh: false,

  init() {
    this._super();
    window.setInterval(() => {
      this.performRefresh();
    }, 5000);
  },

  performRefresh() {
    if (this.get("autoRefresh")) {
      this.get("model").refresh();
    }
  },
});
