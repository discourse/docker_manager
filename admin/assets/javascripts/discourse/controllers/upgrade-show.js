import Controller from "@ember/controller";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { makeArray } from "discourse-common/lib/helpers";
import I18n from "I18n";
import Repo from "../models/repo";

export default class UpgradeShow extends Controller {
  @service messageBus;
  @service dialog;
  @service upgradeStore;

  get complete() {
    return this.upgradeStore.upgradeStatus === "complete";
  }

  get failed() {
    return this.upgradeStore.upgradeStatus === "failed";
  }

  get multiUpgrade() {
    return this.model.length > 1;
  }

  get title() {
    if (this.multiUpgrade) {
      return I18n.t("admin.docker.upgrade_everything");
    } else {
      return I18n.t("admin.docker.upgrade_repo", { name: this.model.name });
    }
  }

  get isUpToDate() {
    return makeArray(this.model).every((repo) => repo.upToDate);
  }

  get upgrading() {
    return makeArray(this.model).some((repo) => repo.upgrading);
  }

  @action
  start() {
    this.upgradeStore.reset();

    if (this.multiUpgrade) {
      for (const repo of this.model) {
        if (!repo.upToDate) {
          repo.upgrading = true;
        }
      }

      return Repo.upgradeAll();
    }

    if (this.model.upgrading) {
      return;
    }

    return this.model.startUpgrade();
  }

  @action
  resetUpgrade() {
    this.dialog.confirm({
      message: I18n.t("admin.docker.reset_warning"),
      didConfirm: async () => {
        if (this.multiUpgrade) {
          try {
            await Repo.resetAll(this.model.filter((repo) => !repo.upToDate));
          } finally {
            this.upgradeStore.reset();

            for (const repo of this.model) {
              repo.upgrading = false;
            }
          }

          return;
        }

        await this.model.resetUpgrade();
        this.upgradeStore.reset();
      },
    });
  }
}
