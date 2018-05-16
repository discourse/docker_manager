import Ember from 'ember';

export default Ember.Component.extend({
  tagName: 'tr',

  upgradeDisabled: function() {
    const upgradingRepo = this.get('upgradingRepo');

    if (!upgradingRepo) {
      const managerRepo = this.get('managerRepo');
      if (!managerRepo) { return false; }
      return (!managerRepo.get('upToDate')) && managerRepo !== this.get('repo');
    }
    return true;
  }.property('upgradingRepo', 'repo', 'managerRepo', 'managerRepo.upToDate'),

  officialRepoImageSrc: function() {
    if (!this.get('repo.official')) return;
    return Discourse.getURL("/plugins/docker_manager/images/font-awesome-check-circle.png");
  }.property('repo.official'),

  actions: {
    upgrade: function() {
      this.sendAction('upgrade', this.get('repo'));
    }
  }
});
