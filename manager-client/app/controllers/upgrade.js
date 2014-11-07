/* global MessageBus, bootbox */
import Ember from 'ember';

export default Ember.ObjectController.extend({

  init: function() {
    this._super();
    this.reset();
  },

  complete: Ember.computed.equal('status', 'complete'),
  failed: Ember.computed.equal('status', 'failed'),

  messageReceived: function(msg) {
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
          this.set('upgrading', false);
        }

        if (msg.value === 'complete') {
          this.set('version', this.get('latest.version'));
        }
        break;
    }
  },

  upgradeButtonText: function() {
    if (this.get('upgrading')) {
      return "Upgrading...";
    } else {
      return "Start Upgrading";
    }
  }.property('upgrading'),

  startBus: function() {
    var self = this;
    MessageBus.subscribe("/docker/upgrade", function(msg) {
      self.messageReceived(msg);
    });
  },

  stopBus: function() {
    MessageBus.unsubscribe("/docker/upgrade");
  },

  reset: function() {
    this.setProperties({ output: '', status: null, percent: 0 });
  },

  actions: {
    start: function() {
      this.reset();
      var repo = this.get('model');
      if (repo.get('upgrading')) { return; }
      repo.startUpgrade();
    },

    resetUpgrade: function() {
      var self = this;

      bootbox.confirm("WARNING: You should only reset upgrades that have failed and are not running.\n\n"+
                      "This will NOT cancel currently running builds and should only be used as a last resort.", function(result) {
        if (result) {
          var repo = self.get('model');
          repo.resetUpgrade().then(function() {
            self.reset();
          });
        }
      });
    }
  },

});
