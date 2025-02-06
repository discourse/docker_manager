import Route from "@ember/routing/route";
import { service } from "@ember/service";
import { bind } from "discourse/lib/decorators";
import { i18n } from "discourse-i18n";
import Repo from "../models/repo";

export default class Upgrade extends Route {
  @service messageBus;
  @service upgradeStore;

  model() {
    return Repo.findAll();
  }

  activate() {
    this.messageBus.subscribe("/docker/update", this.onUpgradeMessage);
  }

  deactivate() {
    this.messageBus.unsubscribe("/docker/update", this.onUpgradeMessage);
  }

  setupController(controller, model) {
    const discourse = model.find((repo) => repo.id === "discourse");

    if (discourse?.branch === "origin/main") {
      // Special case: If the branch is "main" warn user
      controller.appendBannerHtml(
        i18n("admin.docker.main_branch_warning", {
          url: "https://meta.discourse.org/t/17014",
        })
      );
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
        const model = this.modelFor("update");

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
