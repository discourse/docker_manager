import Component from "@glimmer/component";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import DButton from "discourse/components/d-button";
import FormatDate from "discourse/helpers/format-date";
import i18n from "discourse-common/helpers/i18n";
import I18n from "I18n";
import CommitUrl from "../helpers/commit-url";
import NewCommits from "../helpers/new-commits";

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
      return I18n.t("admin.docker.updating");
    } else {
      return I18n.t("admin.docker.update_action");
    }
  }

  @action
  upgrade() {
    this.router.transitionTo("update.show", this.args.repo);
  }

  <template>
    <tr class="repo {{if @repo.hasNewVersion 'new-version'}}">
      <td>
        <div class="repo__name">
          {{#if @repo.linkUrl}}
            <a href={{@repo.linkUrl}} rel="noopener noreferrer" target="_blank">
              {{@repo.nameTitleized}}
            </a>
          {{else}}
            {{@repo.nameTitleized}}
          {{/if}}
        </div>
        {{#if @repo.author}}
          <div class="repo__author">
            {{@repo.author}}
          </div>
        {{/if}}
        {{#if @repo.plugin}}
          <div class="repo__about">
            {{@repo.plugin.about}}
            {{#if @repo.linkUrl}}
              <a
                href={{@repo.linkUrl}}
                rel="noopener noreferrer"
                target="_blank"
              >
                {{i18n "admin.plugins.learn_more"}}
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

      <td>
        {{CommitUrl "current" @repo.version @repo.prettyVersion @repo.url}}
      </td>

      <td>{{FormatDate @repo.latest.date leaveAgo="true"}}</td>
      <td>
        <ul class="repo__latest-version">
          <li>
            {{CommitUrl
              "new"
              @repo.latest.version
              @repo.prettyLatestVersion
              @repo.url
            }}
          </li>
          <li class="new-commits">
            {{NewCommits
              @repo.latest.commits_behind
              @repo.version
              @repo.latest.version
              @repo.url
            }}
          </li>
        </ul>
      </td>
      <td class="repo__status">
        {{#if @repo.checkingStatus}}
          {{i18n "admin.docker.checking"}}
        {{else if @repo.upToDate}}
          {{i18n "admin.docker.up_to_date"}}
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
