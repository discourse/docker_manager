/* global MessageBus, bootbox */
import Ember from 'ember';

export default Ember.Controller.extend({
  output: null,

  init() {
    this._super();
    this.reset();
  },

  complete: Ember.computed.equal('status', 'complete'),
  failed: Ember.computed.equal('status', 'failed'),

  messageReceived(msg) {
    switch(msg.type) {
      case "log":
        this.set('output', this.get('output') + msg.value + "\n");
        break;
      case "percent":
        this.set('percent', msg.value);
        break;
      case "status":
        this.set('status', msg.value);

        if (msg.value === 'complete' || msg.value === 'failed') {
          this.set('model.upgrading', false);
        }

        if (msg.value === 'complete') {
          this.set('version', this.get('latest.version'));
        }
        break;
    }
  },

  upgradeButtonText: function() {
    if (this.get('model.upgrading')) {
      return "Upgrading...";
    } else {
      return "Start Upgrading";
    }
  }.property('model.upgrading'),

  startBus() {
    const self = this;
    MessageBus.subscribe("/docker/upgrade", function(msg) {
      self.messageReceived(msg);
    });
  },

  stopBus() {
    MessageBus.unsubscribe("/docker/upgrade");
  },

  reset() {
    this.setProperties({ output: '', status: null, percent: 0 });
  },

  actions: {
    start() {
      this.reset();
      const repo = this.get('model');
      if (repo.get('upgrading')) { return; }
      repo.startUpgrade();
    },

    resetUpgrade() {
      const self = this;

      bootbox.confirm("WARNING: You should only reset upgrades that have failed and are not running.\n\n"+
                      "This will NOT cancel currently running builds and should only be used as a last resort.", function(result) {
        if (result) {
          const repo = self.get('model');
          repo.resetUpgrade().then(function() {
            self.reset();
          });
        }
      });
    }
  },

});
