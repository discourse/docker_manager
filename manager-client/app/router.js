import EmberRouter from '@ember/routing/router';
import config from 'manager-client/config/environment';

export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}

Router.map(function() {
  this.route("processes");
  this.route("upgrade", { path: "/upgrade/:id" });
});
