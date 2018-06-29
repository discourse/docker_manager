import Repo from 'manager-client/models/repo';
import Ember from 'ember';

export default Ember.Route.extend({

  model: function(params) {
    if (params.id === "all") {
      return Repo.findAll();
    }
    return Repo.find(params.id);
  },

  afterModel: function(model) {
    if (Array.isArray(model)) {
      return Repo.findLatestAll().then(response => {
        JSON.parse(response).repos.forEach(_repo => {
          const repo = model.find(repo => repo.get("path") === _repo.path);
          if (!repo) { return; }
          delete _repo.path;
          repo.set("latest", Ember.Object.create(_repo));
        });

        return Repo.findAllProgress(model.filter(repo => !repo.get("upToDate"))).then(progress => {
          this.set("progress", JSON.parse(progress).progress);
        });
      });
    }

    return Repo.findUpgrading().then(u => {
      if (u && u !== model) {
        return Ember.RSVP.Promise.reject("wat");
      }
      return model.findLatest().then(() => {
        return model.findProgress().then(progress => {
          this.set("progress", progress);
        });
      });
    });

  },

  setupController: function(controller, model) {
    controller.reset();
    controller.setProperties({
      model: Array.isArray(model) ? model : [model],
      output: this.get('progress.logs'),
      percent: this.get('progress.percentage')
    });
    controller.startBus();
  },

  deactivate: function() {
    this.controllerFor('upgrade').stopBus();
  }

});
