import Repo from "discourse/plugins/docker_manager/discourse/models/repo";
import Route from "@ember/routing/route";

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
    const upgradeController = this.controllerFor("upgrade");
    controller.model = model;
    controller.upgrading = null;

    model.forEach((repo) => {
      if (repo.upgrading) {
        controller.upgrading = repo;
      }

      // Special case: Upgrade docker manager first
      if (repo.id === "docker_manager") {
        controller.managerRepo = repo;
      }

      // Special case: If the branch is "main" warn user
      if (repo.id === "discourse" && repo.branch === "origin/main") {
        upgradeController.appendBannerHtml(`
          <b>WARNING:</b>
          Your Discourse is tracking the 'main' branch which may be unstable,
          <a href='https://meta.discourse.org/t/change-tracking-branch-for-your-discourse-instance/17014'>
            we recommend tracking the 'tests-passed' branch</a>.
        `);
      }
    });

    this.loadRepos(model.slice(0));
  }
}
