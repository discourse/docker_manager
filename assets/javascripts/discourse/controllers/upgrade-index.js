import Controller from "@ember/controller";
import { computed } from "@ember/object";
import { inject as service } from "@ember/service";

export default Controller.extend({
  router: service(),

  managerRepo: null,
  upgrading: null,

  upgradeAllButtonDisabled: computed(
    "managerRepo.upToDate",
    "allUpToDate",
    function () {
      return !this.get("managerRepo.upToDate") || this.get("allUpToDate");
    }
  ),

  allUpToDate: computed("model.@each.upToDate", function () {
    return this.get("model").every((repo) => repo.upToDate);
  }),

  actions: {
    upgradeAllButton() {
      this.router.replaceWith("upgrade.show", "all");
    },
  },
});
