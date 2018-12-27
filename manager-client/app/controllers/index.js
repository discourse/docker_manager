import Controller from '@ember/controller';
import { computed } from "@ember/object";

export default Controller.extend({
  managerRepo: null,
  upgrading: null,

  upgradeAllButtonDisabled: computed("managerRepo.upToDate", "allUpToDate", function () {
    return !this.get("managerRepo.upToDate") || this.get("allUpToDate");
  }),

  allUpToDate: computed("model.[].upToDate", function() {
    return this.get("model").every(repo => repo.get("upToDate"));
  }),

  actions: {
    upgradeAllButton() {
      this.replaceRoute("upgrade", "all");
    },
    upgrade(repo) {
      this.transitionToRoute("upgrade", repo);
    }
  }
});
