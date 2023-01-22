import { module, test } from "qunit";
import { setupRenderingTest } from "ember-qunit";
import { render, settled } from "@ember/test-helpers";
import hbs from "htmlbars-inline-precompile";
import Repo from "discourse/plugins/docker_manager/discourse/models/repo";
import { query } from "discourse/tests/helpers/qunit-helpers";

const repoProps = {
  unloaded: false,
  branch: "origin/main",
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
    version: "2b006c0",
  },
};

const managerProps = {
  unloaded: false,
  branch: "origin/main",
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
    version: "0b1fb4b",
  },
};

module("Integration | Component | RepoStatus", function (hooks) {
  setupRenderingTest(hooks);

  test("it renders correctly", async function (assert) {
    this.set("repo", new Repo(repoProps));
    this.set("managerRepo", new Repo(managerProps));

    await render(
      hbs`<RepoStatus @repo={{this.repo}} @managerRepo={{this.managerRepo}} />`
    );

    assert
      .dom("span.current.commit-hash")
      .hasText("v2.2.0.beta6 +98", "tag version is used when present");
    assert
      .dom("span.new.commit-hash")
      .hasText("v2.2.0.beta6 +101", "tag version is used when present");

    assert
      .dom("li.new-commits a")
      .hasText("3 new commits", "shows number of new commits");
    assert.strictEqual(
      query("li.new-commits a").href.trim(),
      "https://github.com/discourse/discourse/compare/8f65e4f...2b006c0",
      "links to GitHub diff page"
    );

    this.repo.pretty_version = null;
    this.repo.latest.pretty_version = null;
    await settled();

    assert.strictEqual(
      query("span.current.commit-hash").textContent.trim(),
      "8f65e4f",
      "commit hash is used when tag version is absent"
    );
    assert.strictEqual(
      query("span.new.commit-hash").textContent.trim(),
      "2b006c0",
      "commit hash is used when tag version is absent"
    );
  });

  test("official check mark", async function (assert) {
    this.set("repo", new Repo(repoProps));
    this.set("managerRepo", new Repo(managerProps));

    await render(
      hbs`<RepoStatus @repo={{this.repo}} @managerRepo={{this.managerRepo}} />`
    );

    assert
      .dom("svg.d-icon-check-circle")
      .doesNotExist("green check is absent when not official");

    this.repo.official = true;
    await settled();

    assert
      .dom("svg.d-icon-check-circle")
      .exists("green check is present when official");
  });

  test("upgrade button", async function (assert) {
    this.set("repo", new Repo(repoProps));
    this.set("managerRepo", new Repo(managerProps));

    await render(
      hbs`<RepoStatus @repo={{this.repo}} @managerRepo={{this.managerRepo}} />`
    );

    assert
      .dom(".upgrade-button")
      .exists("upgrade button is visible when plugin is out-of-date")
      .isNotDisabled(
        "upgrade button is not disabled when docker_manager repo is out-of-date"
      );

    this.managerRepo.version = "022aa3a";
    await settled();

    assert
      .dom(".upgrade-button")
      .isDisabled(
        "upgrade button is disabled when docker_manager repo is not up-to-date"
      );

    this.repo.latest.commits_behind = 0;
    this.repo.version = "2b006c0";
    this.repo.pretty_version = "v2.2.0.beta6 +101";
    await settled();

    assert
      .dom(".upgrade-button")
      .doesNotExist("upgrade button is not visible when plugin is up-to-date");
  });
});
