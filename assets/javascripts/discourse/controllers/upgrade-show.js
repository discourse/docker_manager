import Repo from "discourse/plugins/docker_manager/discourse/models/repo";
import Controller from "@ember/controller";
import { equal } from "@ember/object/computed";
import { computed } from "@ember/object";
import { inject as service } from "@ember/service";

export default Controller.extend({
  dialog: service(),

  output: null,

  init() {
    this._super();
    this.reset();
  },

  complete: equal("status", "complete"),
  failed: equal("status", "failed"),

  multiUpgrade: computed("model.length", function () {
    return this.get("model.length") !== 1;
  }),

  title: computed("model.@each.name", function () {
    return this.get("multiUpgrade") ? "All" : this.get("model")[0].get("name");
  }),

  isUpToDate: computed("model.@each.upToDate", function () {
    return this.get("model").every((repo) => repo.get("upToDate"));
  }),

  upgrading: computed("model.@each.upgrading", function () {
    return this.get("model").some((repo) => repo.get("upgrading"));
  }),

  repos() {
    const model = this.get("model");
    return this.get("isMultiple") ? model : [model];
  },

  updateAttribute(key, value, valueIsKey = false) {
    this.get("model").forEach((repo) => {
      value = valueIsKey ? repo.get(value) : value;
      repo.set(key, value);
    });
  },

  messageReceived(msg) {
    switch (msg.type) {
      case "log":
        this.set("output", this.get("output") + msg.value + "\n");
        break;
      case "percent":
        this.set("percent", msg.value);
        break;
      case "status":
        this.set("status", msg.value);

        if (msg.value === "complete") {
          this.get("model")
            .filter((repo) => repo.get("upgrading"))
            .forEach((repo) => {
              repo.set("version", repo.get("latest.version"));
            });
        }

        if (msg.value === "complete" || msg.value === "failed") {
          this.updateAttribute("upgrading", false);
        }

        break;
    }
  },

  upgradeButtonText: computed("upgrading", function () {
    if (this.get("upgrading")) {
      return "Upgrading...";
    } else {
      return "Start Upgrading";
    }
  }),

  startBus() {
    this.messageBus.subscribe("/docker/upgrade", (msg) => {
      this.messageReceived(msg);
    });
  },

  stopBus() {
    this.messageBus.unsubscribe("/docker/upgrade");
  },

  reset() {
    this.setProperties({ output: "", status: null, percent: 0 });
  },

  actions: {
    start() {
      this.reset();

      if (this.get("multiUpgrade")) {
        this.get("model")
          .filter((repo) => !repo.get("upToDate"))
          .forEach((repo) => repo.set("upgrading", true));
        return Repo.upgradeAll();
      }

      const repo = this.get("model")[0];
      if (repo.get("upgrading")) {
        return;
      }
      repo.startUpgrade();
    },

    resetUpgrade() {
      const message = `
        WARNING: You should only reset upgrades that have failed and are not running.

        This will NOT cancel currently running builds and should only be used as a last resort.
      `;

      this.dialog.confirm({
        message,
        didConfirm: () => {
          if (this.get("multiUpgrade")) {
            return Repo.resetAll(
              this.get("model").filter((repo) => !repo.get("upToDate"))
            ).finally(() => {
              this.reset();
              this.updateAttribute("upgrading", false);
            });
          }

          const repo = this.get("model")[0];
          repo.resetUpgrade().then(() => {
            this.reset();
          });
        },
      });
    },
  },
});
