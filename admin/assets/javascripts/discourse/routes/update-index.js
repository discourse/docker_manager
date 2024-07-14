import Route from "@ember/routing/route";

export default class UpgradeIndex extends Route {
  async model() {
    const model = this.modelFor("update");
    await this.loadRepos(model);
    console.warn("loaded repos");
    return model;
  }

  async loadRepos(list) {
    for (const repo of list) {
      await repo.findLatest();
    }
  }
}
