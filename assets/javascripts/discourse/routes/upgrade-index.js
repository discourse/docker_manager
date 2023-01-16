import Repo from "discourse/plugins/docker_manager/discourse/models/repo";
import Route from "@ember/routing/route";

export default Route.extend({
  model() {
    return Repo.findAll();
  },

  loadRepos(list) {
    if (list.length === 0) {
      return;
    }
    this.loadRepo(list.shift()).then(() => this.loadRepos(list));
  },

  loadRepo(repo) {
    return repo.findLatest();
  },

  setupController(controller, model) {
    const upgradeController = this.controllerFor("upgrade");
    controller.setProperties({ model, upgrading: null });

    model.forEach((repo) => {
      if (repo.get("upgrading")) {
        controller.set("upgrading", repo);
      }

      // Special case: Upgrade docker manager first
      if (repo.get("id") === "docker_manager") {
        controller.set("managerRepo", repo);
      }

      // Special case: If the branch is "main" warn user
      if (
        repo.get("id") === "discourse" &&
        repo.get("branch") === "origin/main"
      ) {
        upgradeController.appendBannerHtml(
          "<b>WARNING:</b> Your Discourse is tracking the 'main' branch which may be unstable, <a href='https://meta.discourse.org/t/change-tracking-branch-for-your-discourse-instance/17014'>we recommend tracking the 'tests-passed' branch</a>."
        );
      }
    });

    this.loadRepos(model.slice(0));
  },
});
