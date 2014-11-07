import Ember from 'ember';

export default Ember.ObjectController.extend({
  needs: ['index'],

  upgradingRepo: Ember.computed.alias('controllers.index.upgrading'),
  managerRepo: Ember.computed.alias('controllers.index.managerRepo'),

  upgradeDisabled: function() {
    var upgradingRepo = this.get('upgradingRepo');

    if (Ember.isNone(upgradingRepo)) {
      var managerRepo = this.get('managerRepo');
      if (!managerRepo) { return false; }
      return (!managerRepo.get('upToDate')) && managerRepo !== this.get('model');
    }
    return true;
  }.property('upgradingRepo', 'model', 'managerRepo', 'managerRepo.upToDate')

});

