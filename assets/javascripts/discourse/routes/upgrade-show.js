import Repo from "discourse/plugins/docker_manager/discourse/models/repo";
import Route from "@ember/routing/route";
import { Promise } from "rsvp";

export default Route.extend({
  model(params) {
    if (params.id === "all") {
      return Repo.findAll();
    }
    return Repo.find(params.id);
  },

  afterModel(model) {
    if (Array.isArray(model)) {
      return Repo.findLatestAll().then((response) => {
        JSON.parse(response).repos.forEach((repoData) => {
          const repo = model.find((_repo) => _repo.path === repoData.path);
          if (!repo) {
            return;
          }
          delete repoData.path;

          for (const [key, value] of Object.entries(repoData)) {
            repo.latest[key] = value;
          }
        });

        return Repo.findAllProgress(
          model.filter((repo) => !repo.upToDate)
        ).then((progress) => {
          this.set("progress", JSON.parse(progress).progress);
        });
      });
    }

    return Repo.findUpgrading().then((u) => {
      if (u && u !== model) {
        return Promise.reject("wat");
      }
      return model.findLatest().then(() => {
        return model.findProgress().then((progress) => {
          this.set("progress", progress);
        });
      });
    });
  },

  setupController(controller, model) {
    controller.reset();
    controller.setProperties({
      model: Array.isArray(model) ? model : [model],
      output: this.get("progress.logs"),
      percent: this.get("progress.percentage"),
    });
    controller.startBus();
  },

  deactivate() {
    this.controllerFor("upgrade.show").stopBus();
  },
});
