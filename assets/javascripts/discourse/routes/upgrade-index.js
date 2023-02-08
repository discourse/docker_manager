import Repo from "discourse/plugins/docker_manager/discourse/models/repo";
import Route from "@ember/routing/route";
import I18n from "I18n";

export default class UpgradeIndex extends Route {
  model() {
    return Repo.findAll();
  }

  async loadRepos(list) {
    if (list.length === 0) {
      return;
    }

    await list.shift().findLatest();

    this.loadRepos(list);
  }

  setupController(controller, model) {
    controller.model = model;

    model.forEach((repo) => {
      // Special case: Upgrade docker manager first
      if (repo.id === "docker_manager") {
        controller.managerRepo = repo;
      }

      // Special case: If the branch is "main" warn user
      if (repo.id === "discourse" && repo.branch === "origin/main") {
        this.controllerFor("upgrade").appendBannerHtml(
          I18n.t("admin.docker.main_branch_warning")
        );
      }
    });

    this.loadRepos(model.slice(0));
  }
}
