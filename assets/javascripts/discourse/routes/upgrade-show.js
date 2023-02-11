import Repo from "discourse/plugins/docker_manager/discourse/models/repo";
import Route from "@ember/routing/route";
import { inject as service } from "@ember/service";

export default class UpgradeShow extends Route {
  @service upgradeStore;

  model(params) {
    if (params.id === "all") {
      return Repo.findAll();
    }

    return Repo.find(params.id);
  }

  async afterModel(model) {
    if (Array.isArray(model)) {
      const repos = await Repo.findLatestAll();

      for (const repoData of repos) {
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

      this.upgradeStore.reset({
        consoleOutput: progress.logs,
        progressPercentage: progress.percentage,
        // repos,
      });

      return;
    }

    await Repo.findUpgrading();
    await model.findLatest();

    const progress = await model.findProgress();
    this.upgradeStore.reset({
      consoleOutput: progress.logs,
      progressPercentage: progress.percentage,
      // repos,
    });
  }
}
