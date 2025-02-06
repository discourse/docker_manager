import Controller from "@ember/controller";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { makeArray } from "discourse/lib/helpers";
import { i18n } from "discourse-i18n";
import Repo from "../models/repo";

export default class UpgradeShow extends Controller {
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
      return i18n("admin.docker.update_everything");
    } else {
      return i18n("admin.docker.update_repo", { name: this.model.name });
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
      message: i18n("admin.docker.reset_warning"),
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
