/* global Discourse */

import request from 'ember-ajax/request';
import Ember from 'ember';

var loaded = [];

var Repo = Ember.Object.extend({

  upToDate: function() {
    return !this.get('upgrading') & (this.get('version') === this.get('latest.version'));
  }.property('upgrading', 'version', 'latest.version'),

  shouldCheck: function() {
    if (Ember.isNone(this.get('version'))) { return false; }
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
    args.data = this.getProperties('path', 'version', 'branch');

    return request(Discourse.getURL(url), args);
  },

  findLatest: function() {
    var self = this;

    return new Ember.RSVP.Promise(function(resolve) {
      if (!self.get('shouldCheck')) { return resolve(); }

      self.set('checking', true);
      self.repoAjax(Discourse.getURL('/admin/docker/latest')).then(function(result) {
        self.setProperties({
          checking: false,
          lastCheckedAt: new Date().getTime(),
          latest: Ember.Object.create(result.latest)
        });
        resolve();
      });
    });
  },

  findProgress: function() {
    return this.repoAjax(Discourse.getURL('/admin/docker/progress')).then(function(result) {
      return result.progress;
    });
  },

  resetUpgrade: function() {
    var self = this;
    return this.repoAjax(Discourse.getURL('/admin/docker/upgrade'), { type: 'DELETE' }).then(function() {
      self.set('upgrading', false);
    });
  },

  startUpgrade: function() {
    var self = this;
    this.set('upgrading', true);

    return this.repoAjax(Discourse.getURL('/admin/docker/upgrade'), { type: 'POST' }).catch(function() {
      self.set('upgrading', false);
    });
  }
});

Repo.reopenClass({
  findAll() {
    return new Ember.RSVP.Promise(function (resolve) {
      if (loaded.length) { return resolve(loaded); }

      request(Discourse.getURL("/admin/docker/repos")).then(function(result) {
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

export default Repo;
