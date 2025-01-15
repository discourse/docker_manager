import { click, currentURL, visit } from "@ember/test-helpers";
import { test } from "qunit";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("docker_manager", function (needs) {
  needs.user({ admin: true });

  test("basic navigation", async function (assert) {
    await visit("/admin");
    assert.dom(".upgrades-banner").exists();

    pretender.get("/admin/docker/repos", () =>
      response({
        repos: [
          {
            name: "discourse",
            path: "/home/user/discourse/discourse",
            branch: "origin/main",
            official: false,
            id: "discourse",
            version: "010370f8b1cfa56cea3736059c96d0578e7918e2",
            pretty_version: "v3.1.0.beta2 +236",
            url: "https://github.com/discourse/discourse.git",
          },
          {
            name: "docker_manager",
            path: "/home/user/discourse/discourse/plugins/docker_manager",
            branch: "origin/v2",
            official: true,
            id: "docker_manager",
            version: "c8bca160d5c04a569217ede084bbf844ecd21644",
            pretty_version: null,
            url: "https://github.com/discourse/docker_manager",
          },
        ],
      })
    );

    pretender.get("/admin/docker/latest", ({ queryParams }) => {
      if (queryParams.path === "/home/user/discourse/discourse") {
        return response({
          latest: {
            path: "/home/user/discourse/discourse",
            version: "8efb787d8758cbe2ddc6a42b79cbdfa0e0b1909a",
            pretty_version: "v3.1.0.beta2 +241",
            commits_behind: 0,
            date: "2023-02-13T10:43:16.000+01:00",
          },
        });
      } else {
        return response({
          latest: {
            path: "/home/user/discourse/discourse/plugins/docker_manager",
            version: "c8bca160d5c04a569217ede084bbf844ecd21644",
            pretty_version: null,
            commits_behind: 0,
            date: "2023-02-13T11:25:49.000+01:00",
          },
        });
      }
    });

    await click(".upgrades-banner a");
    assert.strictEqual(currentURL(), "/admin/update");

    assert.dom(".docker-manager table#repos tbody tr").exists({ count: 2 });
    assert.dom(".new.commit-hash").hasText("v3.1.0.beta2 +241");

    pretender.get("/admin/docker/progress", () =>
      response({
        progress: {
          logs: "",
          percentage: 0,
          status: null,
          repos: ["discourse"],
        },
      })
    );

    await click(".upgrade-button");

    assert.dom("h2").hasText("Update discourse");
    assert.dom("button.start-upgrade").exists();
  });
});
