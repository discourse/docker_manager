import Discourse from "manager-client/discourse";
import Component from "@ember/component";
import { computed } from "@ember/object";
import { inject as service } from "@ember/service";

export default Component.extend({
  router: service(),
  tagName: "tr",

  upgradeDisabled: computed(
    "upgradingRepo",
    "repo",
    "managerRepo",
    "managerRepo.upToDate",
    function () {
      const upgradingRepo = this.get("upgradingRepo");

      if (!upgradingRepo) {
        const managerRepo = this.get("managerRepo");
        if (!managerRepo) {
          return false;
        }
        return !managerRepo.get("upToDate") && managerRepo !== this.get("repo");
      }
      return true;
    }
  ),

  officialRepoImageSrc: computed("repo.official", function () {
    if (this.get("repo.fork")) {
      return Discourse.getAppURL(
        "/plugins/docker_manager/images/font-awesome-exclamation-circle.png"
      );
    } else if (this.get("repo.official")) {
      return Discourse.getAppURL(
        "/plugins/docker_manager/images/font-awesome-check-circle.png"
      );
    }
  }),

  officialRepoImageTitle: computed("repo.official", function () {
    if (this.get("repo.fork")) {
      return "Forked Official Plugin";
    } else if (this.get("repo.official")) {
      return "Official Plugin";
    }
  }),

  actions: {
    upgrade() {
      this.get("router").transitionTo("upgrade", this.get("repo"));
    },
  },
});
