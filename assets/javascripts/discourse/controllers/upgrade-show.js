import Repo from "discourse/plugins/docker_manager/discourse/models/repo";
import Controller from "@ember/controller";
import { inject as service } from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { equal } from "@ember/object/computed";
import { action } from "@ember/object";
import I18n from "I18n";

export default class UpgradeShow extends Controller {
  @service messageBus;
  @service dialog;

  @tracked output = "";
  @tracked status = null;
  @tracked percent = 0;

  @equal("status", "complete") complete;
  @equal("status", "failed") failed;

  get multiUpgrade() {
    return this.model.length !== 1;
  }

  get title() {
    return this.multiUpgrade ? "All" : this.model[0].name;
  }

  get isUpToDate() {
    return this.model.every((repo) => repo.upToDate);
  }

  get upgrading() {
    return this.model.some((repo) => repo.upgrading);
  }

  get repos() {
    return this.isMultiple ? this.model : [this.model];
  }

  updateAttribute(key, value, valueIsKey = false) {
    this.model.forEach((repo) => {
      value = valueIsKey ? repo[value] : value;
      repo[key] = value;
    });
  }

  messageReceived(msg) {
    switch (msg.type) {
      case "log":
        this.output = this.output + msg.value + "\n";
        break;
      case "percent":
        this.percent = msg.value;
        break;
      case "status":
        this.status = msg.value;

        if (msg.value === "complete") {
          this.model
            .filter((repo) => repo.upgrading)
            .forEach((repo) => {
              repo.version = repo.latest?.version;
            });
        }

        if (msg.value === "complete" || msg.value === "failed") {
          this.updateAttribute("upgrading", false);
        }

        break;
    }
  }

  startBus() {
    this.messageBus.subscribe("/docker/upgrade", (msg) => {
      this.messageReceived(msg);
    });
  }

  stopBus() {
    this.messageBus.unsubscribe("/docker/upgrade");
  }

  reset() {
    this.output = "";
    this.status = null;
    this.percent = 0;
  }

  @action
  start() {
    this.reset();

    if (this.multiUpgrade) {
      this.model
        .filter((repo) => !repo.upToDate)
        .forEach((repo) => (repo.upgrading = true));

      return Repo.upgradeAll();
    }

    const repo = this.model[0];
    if (repo.upgrading) {
      return;
    }

    repo.startUpgrade();
  }

  @action
  resetUpgrade() {
    const message = I18n.t("admin.docker.reset_warning");

    this.dialog.confirm({
      message,
      didConfirm: async () => {
        if (this.multiUpgrade) {
          try {
            await Repo.resetAll(this.model.filter((repo) => !repo.upToDate));
          } finally {
            this.reset();
            this.updateAttribute("upgrading", false);
            return;
          }
        }

        const repo = this.model[0];
        await repo.resetUpgrade();
        this.reset();
      },
    });
  }
}
