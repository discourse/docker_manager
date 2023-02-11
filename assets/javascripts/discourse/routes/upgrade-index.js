import Route from "@ember/routing/route";

export default class UpgradeIndex extends Route {
  model() {
    return this.modelFor("upgrade");
  }

  async loadRepos(list) {
    if (list.length === 0) {
      return;
    }

    for (const repo of list) {
      await repo.findLatest();
    }
  }

  setupController(controller, model) {
    super.setupController(...arguments);
    this.loadRepos(model);
  }
}
