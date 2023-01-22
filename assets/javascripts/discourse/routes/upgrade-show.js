import Repo from "discourse/plugins/docker_manager/discourse/models/repo";
import Route from "@ember/routing/route";
import { tracked } from "@glimmer/tracking";

export default class UpgradeShow extends Route {
  @tracked progress;

  model(params) {
    if (params.id === "all") {
      return Repo.findAll();
    }

    return Repo.find(params.id);
  }

  async afterModel(model) {
    if (Array.isArray(model)) {
      const response = await Repo.findLatestAll();

      for (const repoData of JSON.parse(response).repos) {
        const repo = model.find((_repo) => _repo.path === repoData.path);
        if (!repo) {
          return;
        }

        delete repoData.path;

        for (const [key, value] of Object.entries(repoData)) {
          repo.latest[key] = value;
        }
      }

      const progress = await Repo.findAllProgress(
        model.filter((repo) => !repo.upToDate)
      );

      this.progress = JSON.parse(progress).progress;
      return;
    }

    await Repo.findUpgrading();
    await model.findLatest();

    const progress = await model.findProgress();
    this.progress = progress;
  }

  setupController(controller, model) {
    controller.reset();
    controller.model = Array.isArray(model) ? model : [model];
    controller.output = this.progress.logs;
    controller.percent = this.progress.percentage;
    controller.startBus();
  }

  deactivate() {
    this.controllerFor("upgrade.show").stopBus();
  }
}
