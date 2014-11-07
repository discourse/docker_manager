import ProcessList from 'docker-manager/models/process-list';
import Ember from 'ember';

export default Ember.Route.extend({
  model: function() {
    return ProcessList.find();
  }
});
