import { find } from 'manager-client/models/process-list';
import Ember from 'ember';

export default Ember.Route.extend({
  model: find
});
