import ProcessList from "discourse/plugins/docker_manager/discourse/models/process-list";
import Route from "@ember/routing/route";

export default class UpgradeProcesses extends Route {
  async model() {
    const processes = new ProcessList();
    await processes.refresh();

    return processes;
  }
}
