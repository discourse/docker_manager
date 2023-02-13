import ProcessList from "../models/process-list";
import Route from "@ember/routing/route";

export default class UpgradeProcesses extends Route {
  async model() {
    const processes = new ProcessList();
    await processes.refresh();

    return processes;
  }
}
