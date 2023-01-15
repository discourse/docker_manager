import { module, test } from "qunit";
import { setupRenderingTest } from "ember-qunit";
import { render, find } from "@ember/test-helpers";
import hbs from "htmlbars-inline-precompile";
import Repo from "discourse/plugins/docker_manager/discourse/models/repo";

const repoObject = Repo.create({
  unloaded: false,
  branch: "origin/master",
  id: "discourse",
  name: "discourse",
  official: false,
  path: "/c/discourse",
  pretty_version: "v2.2.0.beta6 +98",
  url: "https://github.com/discourse/discourse",
  version: "8f65e4f",
  latest: {
    commits_behind: 3,
    date: "2018-12-26T20:52:07.000+03:00",
    path: "/c/discourse",
    pretty_version: "v2.2.0.beta6 +101",
    version: "2b006c0"
  }
});

const managerRepo = Repo.create({
  unloaded: false,
  branch: "origin/master",
  id: "docker_manager",
  name: "docker_manager",
  official: true,
  path: "/c/discourse/plugins/docker_manager",
  pretty_version: null,
  url: "https://github.com/discourse/docker_manager",
  version: "0b1fb4b",
  latest: {
    commits_behind: 0,
    date: "2018-12-26T20:52:07.000+03:00",
    path: "/c/discourse/plugins/docker_manager",
    pretty_version: null,
    version: "0b1fb4b"
  }
});

module("Integration | Component | repo-status", function(hooks) {
  setupRenderingTest(hooks);

  test("it renders correctly", async function(assert) {
    this.set("repo", repoObject);
    this.set("managerRepo", managerRepo);
    await render(hbs`{{repo-status repo=repo managerRepo=managerRepo}}`);

    assert.equal(
      find("span.current.commit-hash").textContent.trim(),
      "v2.2.0.beta6 +98",
      "tag version is used when present"
    );
    assert.equal(
      find("span.new.commit-hash").textContent.trim(),
      "v2.2.0.beta6 +101",
      "tag version is used when present"
    );

    assert.equal(
      find("li.new-commits a").textContent.trim(),
      "3 new commits",
      "shows number of new commits"
    );
    assert.equal(
      find("li.new-commits a").href.trim(),
      "https://github.com/discourse/discourse/compare/8f65e4f...2b006c0",
      "links to GitHub diff page"
    );

    this.set("repo.pretty_version", null);
    this.set("repo.latest.pretty_version", null);

    assert.equal(
      find("span.current.commit-hash").textContent.trim(),
      "8f65e4f",
      "commit hash is used when tag version is absent"
    );
    assert.equal(
      find("span.new.commit-hash").textContent.trim(),
      "2b006c0",
      "commit hash is used when tag version is absent"
    );

    assert
      .dom("img.check-circle")
      .doesNotExist("green check is absent when not official");
    this.set("repo.official", true);
    assert
      .dom("img.check-circle")
      .exists("green check is present when official");

    assert
      .dom("button.upgrade-button")
      .exists("upgrade button is visible when plugin is out-of-date");

    assert.equal(
      find("button.upgrade-button").disabled,
      false,
      "upgrade button is not disabled when docker_manager repo is up-to-date"
    );
    this.set("managerRepo.upToDate", false);
    assert.equal(
      find("button.upgrade-button").disabled,
      true,
      "upgrade button is disabled when docker_manager repo is out-of-date"
    );

    this.set("repo.latest.commits_behind", 0);
    this.set("repo.version", "2b006c0");
    this.set("repo.pretty_version", "v2.2.0.beta6 +101");
    assert
      .dom("button.upgrade-button")
      .doesNotExist("upgrade button is not visible when plugin is up-to-date");
  });
});
