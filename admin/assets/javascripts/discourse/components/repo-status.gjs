import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import formatDate from "discourse/helpers/format-date";
import icon from "discourse-common/helpers/d-icon";
import i18n from "discourse-common/helpers/i18n";
import commitUrl from "../helpers/commit-url";
import newCommits from "../helpers/new-commits";

export default class RepoStatus extends Component {
  @service router;
  @service upgradeStore;

  get upgradeDisabled() {
    // Allow to see the currently running update
    if (this.args.upgradingRepo) {
      return false;
    }

    // Disable other buttons when an update is running
    if (this.upgradeStore.running) {
      return true;
    }

    // docker_manager has to be updated before other plugins
    return (
      !this.args.managerRepo.upToDate &&
      this.args.managerRepo !== this.args.repo
    );
  }

  get upgradeButtonLabel() {
    if (this.args.repo.upgrading) {
      return i18n("admin.docker.updating");
    } else {
      return i18n("admin.docker.update_action");
    }
  }

  @action
  upgrade() {
    this.router.transitionTo("update.show", this.args.repo);
  }

  <template>
    <tr
      class="d-admin-row__content repo {{if @repo.hasNewVersion 'has-update'}}"
    >
      <td class="d-admin-row__overview">
        <div class="d-admin-row__overview-name">
          {{@repo.nameTitleized}}
        </div>

        {{#if @repo.author}}
          <div class="d-admin-row__overview-author">
            {{@repo.author}}
          </div>
        {{/if}}

        {{#if @repo.plugin}}
          <div class="d-admin-row__overview-about">
            {{@repo.plugin.about}}

            {{#if @repo.linkUrl}}
              <a
                href={{@repo.linkUrl}}
                rel="noopener noreferrer"
                target="_blank"
              >
                {{i18n "admin.plugins.learn_more"}}
                {{icon "up-right-from-square"}}
              </a>
            {{/if}}
          </div>
        {{/if}}

        {{#if @repo.hasNewVersion}}
          <div class="repo__new-version">
            {{i18n "admin.docker.new_version_available"}}
          </div>
        {{/if}}
      </td>

      <td class="d-admin-row__detail">
        <div class="d-admin-row__mobile-label">
          {{i18n "admin.docker.repo.commit_hash"}}
        </div>
        {{commitUrl "current" @repo.version @repo.prettyVersion @repo.url}}
      </td>

      <td class="d-admin-row__detail">
        <div class="d-admin-row__mobile-label">
          {{i18n "admin.docker.repo.last_updated"}}
        </div>
        {{formatDate @repo.latest.date leaveAgo="true"}}
      </td>

      <td class="d-admin-row__detail">
        <div class="d-admin-row__mobile-label">
          {{i18n "admin.docker.repo.latest_version"}}
        </div>
        <div class="repo__latest-version">
          <div>
            {{commitUrl
              "new"
              @repo.latest.version
              @repo.prettyLatestVersion
              @repo.url
            }}
          </div>
          <div class="new-commits">
            {{newCommits
              @repo.latest.commits_behind
              @repo.version
              @repo.latest.version
              @repo.url
            }}
          </div>
        </div>
      </td>

      <td class="d-admin-row__controls">
        {{#if @repo.checkingStatus}}
          <div class="status-label --loading">
            {{i18n "admin.docker.checking"}}
          </div>
        {{else if @repo.upToDate}}
          <div role="status" class="status-label --success">
            <div class="status-label-indicator">
            </div>
            <div class="status-label-text">
              {{i18n "admin.docker.up_to_date"}}
            </div>
          </div>
        {{else}}
          <DButton
            @action={{this.upgrade}}
            @disabled={{this.upgradeDisabled}}
            @translatedLabel={{this.upgradeButtonLabel}}
            class="upgrade-button"
          />
        {{/if}}
      </td>
    </tr>
  </template>
}
