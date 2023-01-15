import Repo from "discourse/plugins/docker_manager/discourse/models/repo";
import Route from "@ember/routing/route";
import EmberObject from "@ember/object";
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
        JSON.parse(response).repos.forEach((_repo) => {
          const repo = model.find((repo) => repo.get("path") === _repo.path);
          if (!repo) {
            return;
          }
          delete _repo.path;
          repo.set("latest", EmberObject.create(_repo));
        });

        return Repo.findAllProgress(
          model.filter((repo) => !repo.get("upToDate"))
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
    this.controllerFor("upgrade").stopBus();
  },
});
