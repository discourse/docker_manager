import { on } from "@ember/modifier";
import RouteTemplate from "ember-route-template";
import DButton from "discourse/components/d-button";
import { i18n } from "discourse-i18n";
import RepoStatus from "../../components/repo-status";

export default RouteTemplate(
  <template>
    <div class="updates-heading">
      {{#unless @controller.outdated}}
        <DButton
          disabled={{@controller.upgradeAllButtonDisabled}}
          id="upgrade-all"
          class="btn btn-primary"
          type="button"
          {{on "click" @controller.upgradeAllButton}}
        >
          {{#if @controller.allUpToDate}}
            {{i18n "admin.docker.all_up_to_date"}}
          {{else}}
            {{i18n "admin.docker.update_all"}}
          {{/if}}
        </DButton>
      {{/unless}}
    </div>

    {{#if @controller.outdated}}
      <h2>{{i18n "admin.docker.outdated_image_header"}}</h2>
      <p>{{i18n "admin.docker.outdated_image_info"}}</p>

      {{!-- prettier-ignore --}}
      <pre>
    cd /var/discourse
    ./launcher rebuild app
  </pre>
      <p>
        <a
          href="https://meta.discourse.org/t/how-do-i-update-my-docker-image-to-latest/23325"
        >
          {{i18n "admin.docker.outdated_image_link"}}
        </a>
      </p>
    {{else}}

      <table class="d-admin-table" id="repos">
        <thead>
          <th>{{i18n "admin.docker.repo.name"}}</th>
          <th>{{i18n "admin.docker.repo.commit_hash"}}</th>
          <th>{{i18n "admin.docker.repo.last_updated"}}</th>
          <th>{{i18n "admin.docker.repo.latest_version"}}</th>
          <th>{{i18n "admin.docker.repo.status"}}</th>
        </thead>
        <tbody>
          {{#each @controller.model as |repo|}}
            <RepoStatus
              @repo={{repo}}
              @upgradingRepo={{repo.upgrading}}
              @managerRepo={{@controller.managerRepo}}
            />
          {{/each}}
        </tbody>
      </table>
    {{/if}}
  </template>
);
