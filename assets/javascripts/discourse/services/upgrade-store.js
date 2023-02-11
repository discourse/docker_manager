import Service from "@ember/service";
import { tracked } from "@glimmer/tracking";

export default class UpgradeStore extends Service {
  @tracked consoleOutput = "";
  @tracked progressPercentage = 0;
  @tracked upgradeStatus = null;

  reset({ consoleOutput, progressPercentage, upgradeStatus } = {}) {
    this.consoleOutput = consoleOutput ?? "";
    this.progressPercentage = progressPercentage ?? 0;
    this.upgradeStatus = upgradeStatus ?? null;
  }
}
