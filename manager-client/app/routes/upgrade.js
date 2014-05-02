import Repo from 'docker-manager/models/repo';

export default Em.Route.extend({

  model: function(params) {
    return Repo.find(params.id);
  },

  afterModel: function(model, transition) {
    var self = this;
    return Repo.findUpgrading().then(function(u) {
      if (u && u !== model) {
        return Ember.RSVP.Promise.reject("wat");
      }
      return model.findLatest().then(function() {
        return model.findProgress().then(function(progress) {
          self.set("progress", progress);
        });
      });
    });

  },

  setupController: function(controller, model) {
    controller.reset();
    controller.setProperties({
      model: model,
      output: this.get('progress.logs'),
      percent: this.get('progress.percentage')
    });
    controller.startBus();
  },

  deactivate: function() {
    this.controllerFor('upgrade').stopBus();
  }

});
