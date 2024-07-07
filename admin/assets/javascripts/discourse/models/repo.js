import { cached, tracked } from "@glimmer/tracking";
import { TrackedObject } from "@ember-compat/tracked-built-ins";
import { ajax } from "discourse/lib/ajax";
import AdminPlugin from "admin/models/admin-plugin";

let loaded = [];
export let needsImageUpgrade = false;

function concatVersions(repos) {
  return repos.map((repo) => repo.version).join(", ");
}

export default class Repo {
  static create() {
    return new Repo(...arguments);
  }

  static async findAll() {
    if (loaded.length) {
      return loaded;
    }

    const result = await ajax("/admin/docker/repos");
    loaded = result.repos.map((r) => new Repo(r));
    needsImageUpgrade = result.upgrade_required;

    return loaded;
  }

  static async findUpgrading() {
    const result = await Repo.findAll();
    return result.findBy("upgrading", true);
  }

  static async find(id) {
    const result = await Repo.findAll();
    return result.findBy("id", id);
  }

  static upgradeAll() {
    return ajax("/admin/docker/update", {
      dataType: "text",
      type: "POST",
      data: { path: "all" },
    });
  }

  static resetAll(repos) {
    return ajax("/admin/docker/update", {
      dataType: "text",
      type: "DELETE",
      data: { path: "all", version: concatVersions(repos) },
    });
  }

  static async findLatestAll() {
    const result = await ajax("/admin/docker/latest", {
      dataType: "json",
      type: "GET",
      data: { path: "all" },
    });
    return result.repos;
  }

  static async findAllProgress(repos) {
    const result = await ajax("/admin/docker/progress", {
      dataType: "json",
      type: "GET",
      data: { path: "all", version: concatVersions(repos) },
    });
    return result.progress;
  }

  @tracked unloaded = true;
  @tracked checking = false;
  @tracked lastCheckedAt = null;
  @tracked latest = new TrackedObject({});
  @tracked plugin = null;

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

    if (attributes.plugin) {
      this.plugin = AdminPlugin.create(attributes.plugin);
    }

    for (const [key, value] of Object.entries(attributes)) {
      if (["latest", "plugin"].includes(key)) {
        continue;
      }

      this[key] = value;
    }
  }

  @cached
  get nameTitleized() {
    if (this.plugin) {
      return this.plugin.nameTitleized;
    }

    return this.name;
  }

  get linkUrl() {
    if (this.plugin) {
      return this.plugin.linkUrl;
    }

    return this.url;
  }

  get author() {
    if (this.plugin) {
      return this.plugin.author;
    }

    return null;
  }

  get checkingStatus() {
    return this.unloaded || this.checking;
  }

  get upToDate() {
    return !this.upgrading && this.version === this.latest?.version;
  }

  get hasNewVersion() {
    return !this.checkingStatus && !this.upToDate;
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
    await this.repoAjax("/admin/docker/update", {
      dataType: "text",
      type: "DELETE",
    });

    this.upgrading = false;
  }

  async startUpgrade() {
    this.upgrading = true;

    try {
      await this.repoAjax("/admin/docker/update", {
        dataType: "text",
        type: "POST",
      });
    } catch (e) {
      this.upgrading = false;
    }
  }
}
