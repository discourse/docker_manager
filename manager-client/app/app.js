import Resolver from 'ember/resolver';
import loadInitializers from 'ember/load-initializers';

var App = Ember.Application.extend({
  modulePrefix: 'docker-manager', // TODO: loaded via config
  Resolver: Resolver
});

loadInitializers(App, 'docker-manager');

export default App;
