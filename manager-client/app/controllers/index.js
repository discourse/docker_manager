import Ember from 'ember';

export default Ember.Controller.extend({
  managerRepo: null,
  upgrading: null,

  upgradeAllButtonDisabled: function () {
    return !this.get("managerRepo.upToDate") || this.get("allUpToDate");
  }.property("managerRepo.upToDate", "allUpToDate"),

  allUpToDate: function() {
    return this.get("model").every(repo => repo.get("upToDate"));
  }.property("model.@each.upToDate"),

  actions: {
    upgradeAllButton() {
      this.replaceRoute("upgrade", "all");
    }
  }
});
