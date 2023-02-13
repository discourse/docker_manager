import Route from "@ember/routing/route";
import { bind } from "discourse-common/utils/decorators";
import { inject as service } from "@ember/service";
import Repo from "../models/repo";
import I18n from "I18n";

export default class Upgrade extends Route {
  @service messageBus;
  @service upgradeStore;

  model() {
    return Repo.findAll();
  }

  activate() {
    this.messageBus.subscribe("/docker/upgrade", this.onUpgradeMessage);
  }

  deactivate() {
    this.messageBus.unsubscribe("/docker/upgrade", this.onUpgradeMessage);
  }

  setupController(controller, model) {
    const discourse = model.find((repo) => repo.id === "discourse");

    if (discourse?.branch === "origin/main") {
      // Special case: If the branch is "main" warn user
      controller.appendBannerHtml(I18n.t("admin.docker.main_branch_warning"));
    }
  }

  @bind
  onUpgradeMessage(msg) {
    switch (msg.type) {
      case "log":
        this.upgradeStore.consoleOutput =
          this.upgradeStore.consoleOutput + msg.value + "\n";
        break;
      case "percent":
        this.upgradeStore.progressPercentage = msg.value;
        break;
      case "status":
        this.upgradeStore.upgradeStatus = msg.value;
        // Get the resolved model
        const model = this.modelFor("upgrade");

        if (msg.value === "complete") {
          for (const repo of model) {
            if (repo.upgrading) {
              repo.version = repo.latest?.version;
            }
          }

          this.session.requiresRefresh = true;
        }

        if (msg.value === "complete" || msg.value === "failed") {
          for (const repo of model) {
            repo.upgrading = false;
          }
        }

        break;
    }
  }
}
