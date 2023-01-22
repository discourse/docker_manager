import Controller from "@ember/controller";
import { inject as service } from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";

export default class UpgradeIndex extends Controller {
  @service router;

  @tracked managerRepo = null;
  @tracked upgrading = null;

  get upgradeAllButtonDisabled() {
    return !this.managerRepo.upToDate || this.allUpToDate;
  }

  get allUpToDate() {
    return this.model.every((repo) => repo.upToDate);
  }

  @action
  upgradeAllButton() {
    this.router.replaceWith("upgrade.show", "all");
  }
}
