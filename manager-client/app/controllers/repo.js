export default Em.ObjectController.extend({
  needs: ['index'],

  upgradingRepo: Em.computed.alias('controllers.index.upgrading'),
  managerRepo: Em.computed.alias('controllers.index.managerRepo'),

  upgradeDisabled: function() {
    var upgradingRepo = this.get('upgradingRepo');

    if (Em.isNone(upgradingRepo)) {
      var managerRepo = this.get('managerRepo');
      if (!managerRepo) { return false; }
      return (!managerRepo.get('upToDate')) && managerRepo !== this.get('model');
    }
    return true;
  }.property('upgradingRepo', 'model', 'managerRepo', 'managerRepo.upToDate')

});

