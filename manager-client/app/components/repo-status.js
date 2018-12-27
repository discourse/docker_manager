import Component from '@ember/component';
import { computed } from "@ember/object";

export default Component.extend({
  tagName: 'tr',

  upgradeDisabled: computed("upgradingRepo", "repo", "managerRepo", "managerRepo.upToDate",  function() {
    const upgradingRepo = this.get('upgradingRepo');

    if (!upgradingRepo) {
      const managerRepo = this.get('managerRepo');
      if (!managerRepo) { return false; }
      return (!managerRepo.get('upToDate')) && managerRepo !== this.get('repo');
    }
    return true;
  }),

  officialRepoImageSrc: computed("repo.official", function() {
    if (!this.get('repo.official')) { return; }
    return Discourse.getURL("/plugins/docker_manager/images/font-awesome-check-circle.png");
  }),

  actions: {
    upgrade() {
      this.upgrade(this.get('repo'));
    }
  }
});
