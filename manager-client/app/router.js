var Router = Ember.Router.extend(); // ensure we don't share routes between all Router instances

Router.map(function() {
  this.route("processes");
  this.resource('upgrade', { path: '/upgrade/:id' });
});

export default Router;
