import ProcessList from 'docker-manager/models/process-list';

export default Em.Route.extend({
  model: function() {
    return ProcessList.find();
  }
});
