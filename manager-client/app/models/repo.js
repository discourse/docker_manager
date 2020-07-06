import Discourse from "manager-client/discourse";
import { default as EmberObject, computed } from "@ember/object";
import { or } from "@ember/object/computed";
import { isNone } from "@ember/utils";
import { Promise } from "rsvp";

let loaded = [];

function concatVersions(repos) {
  return repos.map(repo => repo.get("version")).join(", ");
}

const Repo = EmberObject.extend({
  unloaded: true,
  checking: false,

  checkingStatus: or("unloaded", "checking"),
  upToDate: computed("upgrading", "version", "latest.version", function() {
    return (
      !this.get("upgrading") &
      (this.get("version") === this.get("latest.version"))
    );
  }),

  prettyVersion: computed("version", "pretty_version", function() {
    return this.get("pretty_version") || this.get("version");
  }),

  prettyLatestVersion: computed("latest.{version,pretty_version}", function() {
    return this.get("latest.pretty_version") || this.get("latest.version");
  }),

  shouldCheck: computed(function() {
    if (isNone(this.get("version"))) {
      return false;
    }
    if (this.get("checking")) {
      return false;
    }

    // Only check once every minute
    const lastCheckedAt = this.get("lastCheckedAt");
    if (lastCheckedAt) {
      const ago = new Date().getTime() - lastCheckedAt;
      return ago > 60 * 1000;
    }
    return true;
  }).volatile(),

  repoAjax(url, args) {
    args = args || {};
    args.data = this.getProperties("path", "version", "branch");

    return Em.$.ajax(Discourse.getAppURL(url), args);
  },

  findLatest() {
    return new Promise(resolve => {
      if (!this.get("shouldCheck")) {
        this.set("unloaded", false);
        return resolve();
      }

      this.set("checking", true);
      this.repoAjax(Discourse.getAppURL("/admin/docker/latest")).then(result => {
        this.setProperties({
          unloaded: false,
          checking: false,
          lastCheckedAt: new Date().getTime(),
          latest: EmberObject.create(result.latest)
        });
        resolve();
      });
    });
  },

  findProgress() {
    return this.repoAjax(Discourse.getAppURL("/admin/docker/progress")).then(
      result => result.progress
    );
  },

  resetUpgrade() {
    return this.repoAjax(Discourse.getAppURL("/admin/docker/upgrade"), {
      dataType: "text",
      type: "DELETE"
    }).then(() => {
      this.set("upgrading", false);
    });
  },

  startUpgrade() {
    this.set("upgrading", true);

    return this.repoAjax(Discourse.getAppURL("/admin/docker/upgrade"), {
      dataType: "text",
      type: "POST"
    }).catch(() => {
      this.set("upgrading", false);
    });
  }
});

Repo.reopenClass({
  findAll() {
    return new Promise(resolve => {
      if (loaded.length) {
        return resolve(loaded);
      }

      Em.$.ajax(Discourse.getAppURL("/admin/docker/repos")).then(result => {
        loaded = result.repos.map(r => Repo.create(r));
        resolve(loaded);
      });
    });
  },

  findUpgrading() {
    return this.findAll().then(result => result.findBy("upgrading", true));
  },

  find(id) {
    return this.findAll().then(result => result.findBy("id", id));
  },

  upgradeAll() {
    return Em.$.ajax(Discourse.getAppURL("/admin/docker/upgrade"), {
      dataType: "text",
      type: "POST",
      data: { path: "all" }
    });
  },

  resetAll(repos) {
    return Em.$.ajax(Discourse.getAppURL("/admin/docker/upgrade"), {
      dataType: "text",
      type: "DELETE",
      data: { path: "all", version: concatVersions(repos) }
    });
  },

  findLatestAll() {
    return Em.$.ajax(Discourse.getAppURL("/admin/docker/latest"), {
      dataType: "text",
      type: "GET",
      data: { path: "all" }
    });
  },

  findAllProgress(repos) {
    return Em.$.ajax(Discourse.getAppURL("/admin/docker/progress"), {
      dataType: "text",
      type: "GET",
      data: { path: "all", version: concatVersions(repos) }
    });
  }
});

export default Repo;
