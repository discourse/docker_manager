import Repo from 'docker-manager/models/repo';

export default Em.Route.extend({
  model: function() {
    return Repo.findAll();
  },

  setupController: function(controller, model) {
    var self = this;
    controller.setProperties({ model: model, upgrading: null });

    model.forEach(function(repo) {
      repo.findLatest();
      if (repo.get('upgrading')) {
        controller.set('upgrading', repo);
      }

      // Special case: Upgrade docker manager first
      if (repo.get('id') === 'docker_manager') {
        controller.set('managerRepo', repo);
      }

      // Special case: If the branch is "master" warn user
      if (repo.get('id') === 'discourse' && repo.get('branch') === 'origin/master') {
        self.controllerFor('application').set('showBanner', true);
      }

    });
  },

  actions: {
    upgrade: function(repo) {
      this.transitionTo('upgrade', repo);
    }
  }
});
