import Service from "@ember/service";
import { tracked } from "@glimmer/tracking";

export default class UpgradeStore extends Service {
  @tracked consoleOutput = "";
  @tracked progressPercentage = 0;
  @tracked upgradeStatus = null;
  @tracked repos = [];

  get running() {
    return this.upgradeStatus === "running";
  }

  reset({ consoleOutput, progressPercentage, upgradeStatus, repos } = {}) {
    this.consoleOutput = consoleOutput ?? "";
    this.progressPercentage = progressPercentage ?? 0;
    this.upgradeStatus = upgradeStatus ?? null;
    this.repos = repos ?? [];
  }
}
