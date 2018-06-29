/* global Discourse */

import request from 'ember-ajax/request';
import Ember from 'ember';

let loaded = [];

function concatVersions(repos) {
  return repos.map(repo => repo.get("version")).join(", ");
}

const Repo = Ember.Object.extend({
  unloaded: true,
  checking: false,

  checkingStatus: Ember.computed.or('unloaded', 'checking'),
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
    return new Ember.RSVP.Promise(resolve => {
      if (!this.get('shouldCheck')) {
        this.set('unloaded', false);
        return resolve();
      }

      this.set('checking', true);
      this.repoAjax(Discourse.getURL('/admin/docker/latest')).then(result => {
        this.setProperties({
          unloaded: false,
          checking: false,
          lastCheckedAt: new Date().getTime(),
          latest: Ember.Object.create(result.latest)
        });
        resolve();
      });
    });
  },

  findProgress: function() {
    return this.repoAjax(Discourse.getURL('/admin/docker/progress')).then(result => result.progress);
  },

  resetUpgrade: function() {
    return this.repoAjax(Discourse.getURL('/admin/docker/upgrade'), { dataType: 'text', type: 'DELETE' }).then(() => {
      this.set('upgrading', false);
    });
  },

  startUpgrade: function() {
    this.set('upgrading', true);

    return this.repoAjax(Discourse.getURL('/admin/docker/upgrade'), { dataType: 'text', type: 'POST' }).catch(() => {
      this.set('upgrading', false);
    });
  }
});

Repo.reopenClass({
  findAll() {
    return new Ember.RSVP.Promise(function (resolve) {
      if (loaded.length) { return resolve(loaded); }

      request(Discourse.getURL("/admin/docker/repos")).then(result => {
        loaded = result.repos.map(r => Repo.create(r));
        resolve(loaded);
      });
    });
  },

  findUpgrading: function() {
    return this.findAll().then(result => result.findBy('upgrading', true));
  },

  find: function(id) {
    return this.findAll().then(result => result.findBy('id', id));
  },

  upgradeAll() {
    return request(Discourse.getURL("/admin/docker/upgrade"), { dataType: "text", type: "POST", data: { path: "all" } });
  },

  resetAll(repos) {
    return request(Discourse.getURL("/admin/docker/upgrade"), { dataType: "text", type: "DELETE", data: { path: "all", version: concatVersions(repos) } });
  },

  findLatestAll() {
    return request(Discourse.getURL("/admin/docker/latest"), { dataType: "text", type: "GET", data: { path: "all" } });
  },

  findAllProgress(repos) {
    return request(Discourse.getURL("/admin/docker/progress"), { dataType: "text", type: "GET", data: { path: "all", version: concatVersions(repos) } });
  },
});

export default Repo;
