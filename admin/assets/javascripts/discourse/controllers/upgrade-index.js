import Controller from "@ember/controller";
import { inject as service } from "@ember/service";
import { cached } from "@glimmer/tracking";
import { action } from "@ember/object";
import { needsImageUpgrade } from "discourse/plugins/docker_manager/discourse/models/repo";

export default class UpgradeIndex extends Controller {
  @service router;

  @cached
  get managerRepo() {
    return this.model.find((repo) => repo.id === "docker_manager");
  }

  get outdated() {
    return needsImageUpgrade;
  }

  get upgradeAllButtonDisabled() {
    return !this.managerRepo.upToDate || this.allUpToDate;
  }

  get allUpToDate() {
    return this.model.every((repo) => repo.upToDate);
  }

  @action
  upgradeAllButton() {
    this.router.transitionTo("upgrade.show", "all");
  }
}
