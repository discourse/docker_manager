define("docker-manager/app", 
  ["ember/resolver","ember/load-initializers","exports"],
  function(__dependency1__, __dependency2__, __exports__) {
    "use strict";
    var Resolver = __dependency1__["default"];
    var loadInitializers = __dependency2__["default"];

    var App = Ember.Application.extend({
      modulePrefix: 'docker-manager', // TODO: loaded via config
      Resolver: Resolver
    });

    loadInitializers(App, 'docker-manager');

    __exports__["default"] = App;
  });
define("docker-manager/components/progress-bar", 
  ["exports"],
  function(__exports__) {
    "use strict";
    __exports__["default"] = Em.Component.extend({
      classNameBindings: [':progress'],

      barStyle: function() {
        var percent = parseInt(this.get('percent'), 10);
        if (percent > 0)  {
          if (percent > 100) { percent = 100; }
          return 'width: ' + this.get('percent') + '%';
        }
      }.property('percent')

    });
  });
define("docker-manager/components/x-tab", 
  ["exports"],
  function(__exports__) {
    "use strict";
    __exports__["default"] = Em.Component.extend({
      tagName: 'li',
      classNameBindings: ['active'],
      active: function() {
        return this.get('childViews').anyBy('active');
      }.property('childViews.@each.active')
    });
  });
define("docker-manager/controllers/index", 
  ["exports"],
  function(__exports__) {
    "use strict";
    __exports__["default"] = Em.ObjectController.extend({
      upgrading: null
    });
  });
define("docker-manager/controllers/processes", 
  ["exports"],
  function(__exports__) {
    "use strict";
    __exports__["default"] = Ember.ObjectController.extend({
      autoRefresh: false,

      init: function() {
        this._super();
        var self = this;

        window.setInterval(function() {
          self.performRefresh();
        }, 5000);
      },

      performRefresh: function() {
        if (this.get('autoRefresh')) {
          this.get('model').refresh();
        }
      }

    });
  });
define("docker-manager/controllers/repo", 
  ["exports"],
  function(__exports__) {
    "use strict";
    __exports__["default"] = Em.ObjectController.extend({
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
  });
define("docker-manager/controllers/upgrade", 
  ["exports"],
  function(__exports__) {
    "use strict";
    /* global MessageBus, bootbox */

    __exports__["default"] = Em.ObjectController.extend({

      init: function() {
        this._super();
        this.reset();
      },

      complete: Em.computed.equal('status', 'complete'),
      failed: Em.computed.equal('status', 'failed'),

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
          bootbox.confirm("<p><b>WARNING:</b> You should only reset upgrades that have failed and are not running.</p> <p>This will NOT cancel currently running builds and should only be used as a last resort.</p>", function(cancel) {
            if (cancel) {
              var repo = self.get('model');
              repo.resetUpgrade().then(function() {
                self.reset();
              });
            }
          });
        }
      },

    });
  });
define("docker-manager/helpers/fmt-commit", 
  ["exports"],
  function(__exports__) {
    "use strict";
    __exports__["default"] = Em.Handlebars.makeBoundHelper(function(sha1, url) {
      if (Em.isNone(url)) { return; }
      return new Em.Handlebars.SafeString("(<a href='" + url + "'>" + sha1 + "</a>)");
    });
  });
define("docker-manager/initializers/csrf-token", 
  ["ic-ajax","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var ajax = __dependency1__["default"];

    __exports__["default"] = {
      name: "findCsrfToken",

      initialize: function(container, application) {
        return ajax('/session/csrf').then(function(result) {
          var token = result.csrf;
          $.ajaxPrefilter(function(options, originalOptions, xhr) {
            if (!options.crossDomain) {
              xhr.setRequestHeader('X-CSRF-Token', token);
            }
          });
        });
      }
    };
  });
define("docker-manager/models/process-list", 
  ["ic-ajax","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var ajax = __dependency1__["default"];

    var ProcessList = Em.Object.extend({

      init: function() {
        this._super();
      },

      refresh: function() {
        var self = this;
        return ajax("/admin/docker/ps").then(function(result) {
          self.set('output', result);
          return self;
        });
      }
    });

    ProcessList.reopenClass({
      find: function() {
        var list = ProcessList.create();
        return list.refresh();
      }
    });


    __exports__["default"] = ProcessList;
  });
define("docker-manager/models/repo", 
  ["ic-ajax","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var ajax = __dependency1__["default"];

    var loaded = [];

    var Repo = Em.Object.extend({

      upToDate: function() {
        return this.get('version') === this.get('latest.version');
      }.property('version', 'latest.version'),

      shouldCheck: function() {
        if (Em.isNone(this.get('version'))) { return false; }
        if (this.get('checking')) { return false; }

        // Only check once every minute
        var lastCheckedAt = this.get('lastCheckedAt');
        if (lastCheckedAt) {
          var ago = new Date().getTime() - lastCheckedAt;
          return ago > 60 * 1000;
        }
        return true;
      }.property().volatile(),

      repoAjax: function(url, args) {
        args = args || {};
        args.data = this.getProperties('path', 'version');
        return ajax(url, args);
      },

      findLatest: function() {
        var self = this;

        return new Em.RSVP.Promise(function(resolve, reject) {
          if (!self.get('shouldCheck')) { return resolve(); }

          self.set('checking', true);
          self.repoAjax('/admin/docker/latest').then(function(result) {
            self.setProperties({
              checking: false,
              lastCheckedAt: new Date().getTime(),
              latest: Em.Object.create(result.latest)
            });
            resolve();
          });
        });
      },

      findProgress: function() {
        return this.repoAjax('/admin/docker/progress').then(function(result) {
          return result.progress;
        });
      },

      resetUpgrade: function() {
        var self = this;
        return this.repoAjax('/admin/docker/upgrade', { type: 'DELETE' }).then(function() {
          self.set('upgrading', false);
        });
      },

      startUpgrade: function() {
        var self = this;
        this.set('upgrading', true);

        return this.repoAjax('/admin/docker/upgrade', { type: 'POST' }).catch(function() {
          self.set('upgrading', false);
        });
      }
    });

    Repo.reopenClass({
      findAll: function() {
        return new Em.RSVP.Promise(function (resolve) {
          if (loaded.length) { return resolve(loaded); }

          ajax("/admin/docker/repos").then(function(result) {
            loaded = result.repos.map(function(r) {
              return Repo.create(r);
            });
            resolve(loaded);
          });
        });
      },

      findUpgrading: function() {
        return this.findAll().then(function(result) {
          return result.findBy('upgrading', true);
        });
      },

      find: function(id) {
        return this.findAll().then(function(result) {
          return result.findBy('id', id);
        });
      },

    });

    __exports__["default"] = Repo;
  });
define("docker-manager/router", 
  ["exports"],
  function(__exports__) {
    "use strict";
    var Router = Ember.Router.extend(); // ensure we don't share routes between all Router instances

    Router.map(function() {
      this.route("processes");
      this.resource('upgrade', { path: '/upgrade/:id' });
    });

    __exports__["default"] = Router;
  });
define("docker-manager/routes/index", 
  ["docker-manager/models/repo","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var Repo = __dependency1__["default"];

    __exports__["default"] = Em.Route.extend({
      model: function() {
        return Repo.findAll();
      },

      setupController: function(controller, model) {
        controller.setProperties({ model: model, upgrading: null });

        model.forEach(function(repo) {
          repo.findLatest();
          if (repo.get('upgrading')) {
            controller.set('upgrading', repo);
          }

          // Special case: Upgrade docker manager first
          if (repo.get('id') === 'docker_manager') {
            controller.set('managerRepo', repo);
          }
        });
      },

      actions: {
        upgrade: function(repo) {
          this.transitionTo('upgrade', repo);
        }
      }
    });
  });
define("docker-manager/routes/processes", 
  ["docker-manager/models/process-list","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var ProcessList = __dependency1__["default"];

    __exports__["default"] = Em.Route.extend({
      model: function() {
        return ProcessList.find();
      }
    });
  });
define("docker-manager/routes/upgrade", 
  ["docker-manager/models/repo","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var Repo = __dependency1__["default"];

    __exports__["default"] = Em.Route.extend({

      model: function(params) {
        return Repo.find(params.id);
      },

      afterModel: function(model, transition) {
        var self = this;
        return Repo.findUpgrading().then(function(u) {
          if (u && u !== model) {
            return Ember.RSVP.Promise.reject("wat");
          }
          return model.findLatest().then(function() {
            return model.findProgress().then(function(progress) {
              self.set("progress", progress);
            });
          });
        });

      },

      setupController: function(controller, model) {
        controller.reset();
        controller.setProperties({
          model: model,
          output: this.get('progress.logs'),
          percent: this.get('progress.percentage')
        });
        controller.startBus();
      },

      deactivate: function() {
        this.controllerFor('upgrade').stopBus();
      }

    });
  });
define("docker-manager/utils/ajax", 
  ["exports"],
  function(__exports__) {
    "use strict";
    /* global ic */
    __exports__["default"] = function ajax(){
      return ic.ajax.apply(null, arguments);
    }
  });
define("docker-manager/views/loading", 
  ["exports"],
  function(__exports__) {
    "use strict";
    __exports__["default"] = Em.View.extend({
      _showOnInsert: function() {
        var self = this;
        self.set('runner', Em.run.later(function() {
          self.$('h3').show();
        }, 200));
      }.on('didInsertElement'),

      _cancelFade: function() {
        Em.run.cancel(this.get('runner'));
      }.on('willDestroyElement')
    });
  });
define("docker-manager/views/processes", 
  ["exports"],
  function(__exports__) {
    "use strict";
    __exports__["default"] = Em.View.extend({

      _insertedIntoDOM: function() {
        this.set('controller.autoRefresh', true);
      }.on('didInsertElement'),

      _removedFromDOM: function() {
        this.set('controller.autoRefresh', false);
      }.on('willDestroyElement')

    });
  });
//# sourceMappingURL=app.js.map
define('docker-manager/templates/application', ['exports'], function(__exports__){ __exports__['default'] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  var buffer = '', stack1, helper, options, self=this, helperMissing=helpers.helperMissing;

function program1(depth0,data) {
  
  
  data.buffer.push("<img src=\"/assets/images/docker-manager-ea64623b074c8ec2b0303bae846e21e6.png\" class=\"logo\">");
  }

function program3(depth0,data) {
  
  
  data.buffer.push("Docker Manager");
  }

function program5(depth0,data) {
  
  
  data.buffer.push("Home");
  }

function program7(depth0,data) {
  
  
  data.buffer.push("Processes");
  }

  data.buffer.push("<header class=\"container\">\n  ");
  stack1 = (helper = helpers['link-to'] || (depth0 && depth0['link-to']),options={hash:{},hashTypes:{},hashContexts:{},inverse:self.noop,fn:self.program(1, program1, data),contexts:[depth0],types:["STRING"],data:data},helper ? helper.call(depth0, "index", options) : helperMissing.call(depth0, "link-to", "index", options));
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n  <h1>");
  stack1 = (helper = helpers['link-to'] || (depth0 && depth0['link-to']),options={hash:{},hashTypes:{},hashContexts:{},inverse:self.noop,fn:self.program(3, program3, data),contexts:[depth0],types:["STRING"],data:data},helper ? helper.call(depth0, "index", options) : helperMissing.call(depth0, "link-to", "index", options));
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("</h1>\n</header>\n\n\n<div class=\"container\">\n\n  <ul class=\"nav nav-tabs\">\n    ");
  stack1 = (helper = helpers['x-tab'] || (depth0 && depth0['x-tab']),options={hash:{
    'route': ("index")
  },hashTypes:{'route': "STRING"},hashContexts:{'route': depth0},inverse:self.noop,fn:self.program(5, program5, data),contexts:[],types:[],data:data},helper ? helper.call(depth0, options) : helperMissing.call(depth0, "x-tab", options));
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n    ");
  stack1 = (helper = helpers['x-tab'] || (depth0 && depth0['x-tab']),options={hash:{
    'route': ("processes")
  },hashTypes:{'route': "STRING"},hashContexts:{'route': depth0},inverse:self.noop,fn:self.program(7, program7, data),contexts:[],types:[],data:data},helper ? helper.call(depth0, options) : helperMissing.call(depth0, "x-tab", options));
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n  </ul>\n\n  ");
  stack1 = helpers._triageMustache.call(depth0, "outlet", {hash:{},hashTypes:{},hashContexts:{},contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n</div>\n");
  return buffer;
  
}); });

define('docker-manager/templates/components/progress-bar', ['exports'], function(__exports__){ __exports__['default'] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  var buffer = '', escapeExpression=this.escapeExpression;


  data.buffer.push("<div class=\"progress-bar\" ");
  data.buffer.push(escapeExpression(helpers['bind-attr'].call(depth0, {hash:{
    'style': ("barStyle")
  },hashTypes:{'style': "STRING"},hashContexts:{'style': depth0},contexts:[],types:[],data:data})));
  data.buffer.push("></div>\n");
  return buffer;
  
}); });

define('docker-manager/templates/components/x-tab', ['exports'], function(__exports__){ __exports__['default'] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  var buffer = '', stack1, helper, options, self=this, helperMissing=helpers.helperMissing;

function program1(depth0,data) {
  
  var stack1;
  stack1 = helpers._triageMustache.call(depth0, "yield", {hash:{},hashTypes:{},hashContexts:{},contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  else { data.buffer.push(''); }
  }

  stack1 = (helper = helpers['link-to'] || (depth0 && depth0['link-to']),options={hash:{},hashTypes:{},hashContexts:{},inverse:self.noop,fn:self.program(1, program1, data),contexts:[depth0],types:["ID"],data:data},helper ? helper.call(depth0, "route", options) : helperMissing.call(depth0, "link-to", "route", options));
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n");
  return buffer;
  
}); });

define('docker-manager/templates/index', ['exports'], function(__exports__){ __exports__['default'] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  var buffer = '', stack1, escapeExpression=this.escapeExpression, helperMissing=helpers.helperMissing, self=this;

function program1(depth0,data) {
  
  var buffer = '', stack1, helper, options;
  data.buffer.push("\n    <tr>\n      <td>\n        ");
  stack1 = helpers._triageMustache.call(depth0, "name", {hash:{},hashTypes:{},hashContexts:{},contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n        ");
  data.buffer.push(escapeExpression((helper = helpers['fmt-commit'] || (depth0 && depth0['fmt-commit']),options={hash:{},hashTypes:{},hashContexts:{},contexts:[depth0,depth0],types:["ID","ID"],data:data},helper ? helper.call(depth0, "version", "url", options) : helperMissing.call(depth0, "fmt-commit", "version", "url", options))));
  data.buffer.push("\n      </td>\n      <td>\n        ");
  stack1 = helpers['if'].call(depth0, "checking", {hash:{},hashTypes:{},hashContexts:{},inverse:self.program(4, program4, data),fn:self.program(2, program2, data),contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n      </td>\n    </tr>\n    ");
  return buffer;
  }
function program2(depth0,data) {
  
  
  data.buffer.push("\n          Checking for new version...\n        ");
  }

function program4(depth0,data) {
  
  var buffer = '', stack1;
  data.buffer.push("\n          ");
  stack1 = helpers['if'].call(depth0, "upToDate", {hash:{},hashTypes:{},hashContexts:{},inverse:self.program(7, program7, data),fn:self.program(5, program5, data),contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n        ");
  return buffer;
  }
function program5(depth0,data) {
  
  
  data.buffer.push("\n            Up to date\n          ");
  }

function program7(depth0,data) {
  
  var buffer = '', stack1, helper, options;
  data.buffer.push("\n            <div class='new-version'>\n              <h4>New Version Available!</h4>\n              <ul>\n                <li>Remote Version: ");
  data.buffer.push(escapeExpression((helper = helpers['fmt-commit'] || (depth0 && depth0['fmt-commit']),options={hash:{},hashTypes:{},hashContexts:{},contexts:[depth0,depth0],types:["ID","ID"],data:data},helper ? helper.call(depth0, "latest.version", "url", options) : helperMissing.call(depth0, "fmt-commit", "latest.version", "url", options))));
  data.buffer.push("</li>\n                <li>Last Updated: ");
  stack1 = helpers._triageMustache.call(depth0, "latest.date", {hash:{},hashTypes:{},hashContexts:{},contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("</li>\n                <li class='new-commits'>");
  stack1 = helpers._triageMustache.call(depth0, "latest.commits_behind", {hash:{},hashTypes:{},hashContexts:{},contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push(" new commits</li>\n              </ul>\n              ");
  stack1 = helpers['if'].call(depth0, "upgrading", {hash:{},hashTypes:{},hashContexts:{},inverse:self.program(10, program10, data),fn:self.program(8, program8, data),contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n            </div>\n          ");
  return buffer;
  }
function program8(depth0,data) {
  
  var buffer = '';
  data.buffer.push("\n                <button class=\"btn\" ");
  data.buffer.push(escapeExpression(helpers.action.call(depth0, "upgrade", "", {hash:{},hashTypes:{},hashContexts:{},contexts:[depth0,depth0],types:["ID","ID"],data:data})));
  data.buffer.push(">Currently Upgrading...</button>\n              ");
  return buffer;
  }

function program10(depth0,data) {
  
  var buffer = '';
  data.buffer.push("\n                <button class=\"btn\" ");
  data.buffer.push(escapeExpression(helpers.action.call(depth0, "upgrade", "", {hash:{},hashTypes:{},hashContexts:{},contexts:[depth0,depth0],types:["ID","ID"],data:data})));
  data.buffer.push(" ");
  data.buffer.push(escapeExpression(helpers['bind-attr'].call(depth0, {hash:{
    'disabled': ("upgradeDisabled")
  },hashTypes:{'disabled': "STRING"},hashContexts:{'disabled': depth0},contexts:[],types:[],data:data})));
  data.buffer.push(">Upgrade to the Latest Version</button>\n              ");
  return buffer;
  }

  data.buffer.push("<h3>Repositories</h3>\n\n<table class='table' id='repos'>\n  <tr>\n    <th style='width: 50%'>Name</th>\n    <th>Status</th>\n  </tr>\n  <tbody>\n    ");
  stack1 = helpers.each.call(depth0, "model", {hash:{
    'itemController': ("repo")
  },hashTypes:{'itemController': "STRING"},hashContexts:{'itemController': depth0},inverse:self.noop,fn:self.program(1, program1, data),contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n  </tbody>\n</table>\n");
  return buffer;
  
}); });

define('docker-manager/templates/loading', ['exports'], function(__exports__){ __exports__['default'] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  


  data.buffer.push("<h3 class='loading'>Loading...</h3>\n");
  
}); });

define('docker-manager/templates/processes', ['exports'], function(__exports__){ __exports__['default'] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  var buffer = '', stack1;


  data.buffer.push("<h3>Processes</h3>\n\n<div class='logs'>");
  stack1 = helpers._triageMustache.call(depth0, "output", {hash:{},hashTypes:{},hashContexts:{},contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("</div>\n");
  return buffer;
  
}); });

define('docker-manager/templates/upgrade', ['exports'], function(__exports__){ __exports__['default'] = Ember.Handlebars.template(function anonymous(Handlebars,depth0,helpers,partials,data) {
this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Ember.Handlebars.helpers); data = data || {};
  var buffer = '', stack1, helper, options, helperMissing=helpers.helperMissing, escapeExpression=this.escapeExpression, self=this;

function program1(depth0,data) {
  
  
  data.buffer.push("\n  <p>Upgrade completed successfully!</p>\n  <p>Note: The web server restarts in the background. It's a good idea to wait 30 seconds or so\n     before refreshing your browser to see the latest version of the application.</p>\n");
  }

function program3(depth0,data) {
  
  
  data.buffer.push("\n  <p>Sorry, there wasn an error upgrading Discourse. Please check the logs.</p>\n");
  }

function program5(depth0,data) {
  
  var buffer = '', stack1, helper, options;
  data.buffer.push("\n  <p>");
  stack1 = helpers._triageMustache.call(depth0, "name", {hash:{},hashTypes:{},hashContexts:{},contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push(" is at the newest version ");
  data.buffer.push(escapeExpression((helper = helpers['fmt-commit'] || (depth0 && depth0['fmt-commit']),options={hash:{},hashTypes:{},hashContexts:{},contexts:[depth0,depth0],types:["ID","ID"],data:data},helper ? helper.call(depth0, "version", "url", options) : helperMissing.call(depth0, "fmt-commit", "version", "url", options))));
  data.buffer.push(".</p>\n");
  return buffer;
  }

function program7(depth0,data) {
  
  var buffer = '', stack1;
  data.buffer.push("\n  <div style='clear: both'>\n    <button ");
  data.buffer.push(escapeExpression(helpers.action.call(depth0, "start", {hash:{},hashTypes:{},hashContexts:{},contexts:[depth0],types:["ID"],data:data})));
  data.buffer.push(" ");
  data.buffer.push(escapeExpression(helpers['bind-attr'].call(depth0, {hash:{
    'disabled': ("upgrading")
  },hashTypes:{'disabled': "STRING"},hashContexts:{'disabled': depth0},contexts:[],types:[],data:data})));
  data.buffer.push(" class='btn'>");
  stack1 = helpers._triageMustache.call(depth0, "upgradeButtonText", {hash:{},hashTypes:{},hashContexts:{},contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("</button>\n    ");
  stack1 = helpers['if'].call(depth0, "upgrading", {hash:{},hashTypes:{},hashContexts:{},inverse:self.noop,fn:self.program(8, program8, data),contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n  </div>\n");
  return buffer;
  }
function program8(depth0,data) {
  
  var buffer = '';
  data.buffer.push("\n      <button ");
  data.buffer.push(escapeExpression(helpers.action.call(depth0, "resetUpgrade", {hash:{},hashTypes:{},hashContexts:{},contexts:[depth0],types:["ID"],data:data})));
  data.buffer.push(" class=\"btn unlock\">Reset Upgrade</button>\n    ");
  return buffer;
  }

  data.buffer.push("<h3>Upgrade ");
  stack1 = helpers._triageMustache.call(depth0, "name", {hash:{},hashTypes:{},hashContexts:{},contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("</h3>\n\n");
  data.buffer.push(escapeExpression((helper = helpers['progress-bar'] || (depth0 && depth0['progress-bar']),options={hash:{
    'percent': ("percent")
  },hashTypes:{'percent': "ID"},hashContexts:{'percent': depth0},contexts:[],types:[],data:data},helper ? helper.call(depth0, options) : helperMissing.call(depth0, "progress-bar", options))));
  data.buffer.push("\n\n");
  stack1 = helpers['if'].call(depth0, "complete", {hash:{},hashTypes:{},hashContexts:{},inverse:self.noop,fn:self.program(1, program1, data),contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n\n");
  stack1 = helpers['if'].call(depth0, "failed", {hash:{},hashTypes:{},hashContexts:{},inverse:self.noop,fn:self.program(3, program3, data),contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n\n");
  stack1 = helpers['if'].call(depth0, "upToDate", {hash:{},hashTypes:{},hashContexts:{},inverse:self.program(7, program7, data),fn:self.program(5, program5, data),contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("\n\n<div class='logs'>");
  stack1 = helpers._triageMustache.call(depth0, "output", {hash:{},hashTypes:{},hashContexts:{},contexts:[depth0],types:["ID"],data:data});
  if(stack1 || stack1 === 0) { data.buffer.push(stack1); }
  data.buffer.push("</div>\n");
  return buffer;
  
}); });