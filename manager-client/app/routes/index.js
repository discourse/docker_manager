import Repo from 'docker-manager/models/repo';

export default Em.Route.extend({
  model: function() {
    return Repo.findAll();
  },

  setupController: function(controller, model) {
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
    });
  },

  actions: {
    upgrade: function(repo) {
      var self = this;
      // Special case: If the branch is "master" warn user
      if (repo.get('id') === 'discourse' && repo.get('branch') === 'origin/master') {
        bootbox.confirm('<p><b>WARNING:</b> Your Discourse instance is tracking "master" branch which may be unstable, we recommend tracking "tests-passed" branch.</p> <p>To continue upgrading press "OK".</p>', function(confirmed) {
          if(confirmed) {
            self.transitionTo('upgrade', repo);
          }
        });
      } else {
        self.transitionTo('upgrade', repo);
      }

    }
  }
});
