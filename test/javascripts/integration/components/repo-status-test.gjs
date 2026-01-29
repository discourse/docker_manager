import { getOwner } from "@ember/owner";
import { render, settled } from "@ember/test-helpers";
import { setupRenderingTest } from "ember-qunit";
import { module, test } from "qunit";
import RepoStatus from "discourse/plugins/docker_manager/discourse/components/repo-status";

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

  test("renders correctly", async function (assert) {
    const store = getOwner(this).lookup("service:store");
    this.set("repo", store.createRecord("repo", repoProps));
    this.set("managerRepo", store.createRecord("repo", managerProps));

    await render(
      <template>
        <RepoStatus @repo={{this.repo}} @managerRepo={{this.managerRepo}} />
      </template>
    );

    assert
      .dom("a.current.commit-hash")
      .hasText("v2.2.0.beta6 +98", "tag version is used when present");
    assert
      .dom("a.new.commit-hash")
      .hasText("v2.2.0.beta6 +101", "tag version is used when present");

    assert
      .dom("div.new-commits a")
      .hasText("3 new commits", "shows number of new commits");
    assert
      .dom("div.new-commits a")
      .hasAttribute(
        "href",
        "https://github.com/discourse/discourse/compare/8f65e4f...2b006c0",
        "links to GitHub diff page"
      );

    this.repo.pretty_version = null;
    this.repo.latest.pretty_version = null;
    await settled();

    assert
      .dom("a.current.commit-hash")
      .hasText("8f65e4f", "commit hash is used when tag version is absent");
    assert
      .dom("a.new.commit-hash")
      .hasText("2b006c0", "commit hash is used when tag version is absent");
  });

  test("official plugin", async function (assert) {
    const store = getOwner(this).lookup("service:store");
    this.set(
      "repo",
      store.createRecord("repo", {
        ...repoProps,
        plugin: { name: "discourse", isOfficial: true },
      })
    );
    this.set("managerRepo", store.createRecord("repo", managerProps));

    await render(
      <template>
        <RepoStatus @repo={{this.repo}} @managerRepo={{this.managerRepo}} />
      </template>
    );

    assert
      .dom("div.d-admin-row__overview-author")
      .hasText("By Discourse", "shows plugin author");
  });

  test("update button", async function (assert) {
    const store = getOwner(this).lookup("service:store");
    this.set("repo", store.createRecord("repo", repoProps));
    this.set("managerRepo", store.createRecord("repo", managerProps));

    await render(
      <template>
        <RepoStatus @repo={{this.repo}} @managerRepo={{this.managerRepo}} />
      </template>
    );

    assert
      .dom(".upgrade-button")
      .exists("update button is visible when plugin is out-of-date")
      .isNotDisabled(
        "update button is not disabled when docker_manager repo is out-of-date"
      );

    this.managerRepo.version = "022aa3a";
    await settled();

    assert
      .dom(".upgrade-button")
      .isDisabled(
        "update button is disabled when docker_manager repo is not up-to-date"
      );

    this.repo.latest.commits_behind = 0;
    this.repo.version = "2b006c0";
    this.repo.pretty_version = "v2.2.0.beta6 +101";
    await settled();

    assert
      .dom(".upgrade-button")
      .doesNotExist("update button is not visible when plugin is up-to-date");
  });
});
