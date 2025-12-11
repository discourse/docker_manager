import { cached } from "@glimmer/tracking";
import Controller from "@ember/controller";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { needsImageUpgrade } from "../../models/repo";

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
    this.router.transitionTo("update.show", "all");
  }
}
