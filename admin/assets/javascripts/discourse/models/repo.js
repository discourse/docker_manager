import { ajax } from "discourse/lib/ajax";
import { tracked } from "@glimmer/tracking";
import { TrackedObject } from "@ember-compat/tracked-built-ins";

let loaded = [];
export let needsImageUpgrade = false;

function concatVersions(repos) {
  return repos.map((repo) => repo.version).join(", ");
}

export default class Repo {
  @tracked unloaded = true;
  @tracked checking = false;
  @tracked lastCheckedAt = null;
  @tracked latest = new TrackedObject({});

  // model attributes
  @tracked name = null;
  @tracked path = null;
  @tracked branch = null;
  @tracked official = false;
  @tracked fork = false;
  @tracked id = null;
  @tracked version = null;
  @tracked pretty_version = null;
  @tracked url = null;
  @tracked upgrading = false;

  constructor(attributes = {}) {
    if (attributes.latest) {
      for (const [key, value] of Object.entries(attributes.latest)) {
        this.latest[key] = value;
      }
    }

    for (const [key, value] of Object.entries(attributes)) {
      if (key === "latest") {
        continue;
      }

      this[key] = value;
    }
  }

  get checkingStatus() {
    return this.unloaded || this.checking;
  }

  get upToDate() {
    return !this.upgrading && this.version === this.latest?.version;
  }

  get prettyVersion() {
    return this.pretty_version || this.version?.substring(0, 8);
  }

  get prettyLatestVersion() {
    return this.latest?.pretty_version || this.latest?.version?.substring(0, 8);
  }

  get shouldCheck() {
    if (this.version === null) {
      return false;
    }

    if (this.checking) {
      return false;
    }

    // Only check once every minute
    if (this.lastCheckedAt) {
      const ago = new Date().getTime() - this.lastCheckedAt;
      return ago > 60 * 1000;
    }

    return true;
  }

  repoAjax(url, args = {}) {
    args.data = {
      path: this.path,
      version: this.version,
      branch: this.branch,
    };

    return ajax(url, args);
  }

  async findLatest() {
    if (!this.shouldCheck) {
      this.unloaded = false;
      return;
    }

    this.checking = true;

    const result = await this.repoAjax("/admin/docker/latest");

    this.unloaded = false;
    this.checking = false;
    this.lastCheckedAt = new Date().getTime();

    for (const [key, value] of Object.entries(result.latest)) {
      this.latest[key] = value;
    }
  }

  async findProgress() {
    const result = await this.repoAjax("/admin/docker/progress");
    return result.progress;
  }

  async resetUpgrade() {
    await this.repoAjax("/admin/docker/upgrade", {
      dataType: "text",
      type: "DELETE",
    });

    this.upgrading = false;
  }

  async startUpgrade() {
    this.upgrading = true;

    try {
      await this.repoAjax("/admin/docker/upgrade", {
        dataType: "text",
        type: "POST",
      });
    } catch (e) {
      this.upgrading = false;
    }
  }
}

Repo.findAll = async function () {
  if (loaded.length) {
    return loaded;
  }

  const result = await ajax("/admin/docker/repos");
  loaded = result.repos.map((r) => new Repo(r));
  needsImageUpgrade = result.upgrade_required;

  return loaded;
};

Repo.findUpgrading = async function () {
  const result = await Repo.findAll();
  return result.findBy("upgrading", true);
};

Repo.find = async function (id) {
  const result = await Repo.findAll();
  return result.findBy("id", id);
};

Repo.upgradeAll = function () {
  return ajax("/admin/docker/upgrade", {
    dataType: "text",
    type: "POST",
    data: { path: "all" },
  });
};

Repo.resetAll = function (repos) {
  return ajax("/admin/docker/upgrade", {
    dataType: "text",
    type: "DELETE",
    data: { path: "all", version: concatVersions(repos) },
  });
};

Repo.findLatestAll = async function () {
  const result = await ajax("/admin/docker/latest", {
    dataType: "json",
    type: "GET",
    data: { path: "all" },
  });
  return result.repos;
};

Repo.findAllProgress = async function (repos) {
  const result = await ajax("/admin/docker/progress", {
    dataType: "json",
    type: "GET",
    data: { path: "all", version: concatVersions(repos) },
  });
  return result.progress;
};
