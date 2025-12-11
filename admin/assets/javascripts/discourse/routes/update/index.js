import Route from "@ember/routing/route";

export default class UpgradeIndex extends Route {
  model() {
    return this.modelFor("update");
  }

  async loadRepos(list) {
    for (const repo of list) {
      await repo.findLatest();
    }
  }

  setupController(controller, model) {
    super.setupController(...arguments);
    this.loadRepos(model);
  }
}
