import Route from "@ember/routing/route";
import { cancel } from "@ember/runloop";
import { bind } from "discourse/lib/decorators";
import discourseLater from "discourse/lib/later";
import ProcessList from "../models/process-list";

const REFRESH_INTERVAL = 5000;

export default class UpgradeProcesses extends Route {
  processes = null;
  refreshTimer = null;
  autoRefresh = false;

  model() {
    this.processes = new ProcessList();
    this.autoRefresh = true;
    this.refresh();

    return this.processes;
  }

  deactivate() {
    this.autoRefresh = false;
  }

  @bind
  async refresh() {
    if (this.autoRefresh) {
      await this.processes.refresh();
      this.refreshTimer = discourseLater(this.refresh, REFRESH_INTERVAL);
    } else {
      cancel(this.refreshTimer);
    }
  }
}
