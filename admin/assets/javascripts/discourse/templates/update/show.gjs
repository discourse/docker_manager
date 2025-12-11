import { on } from "@ember/modifier";
import RouteTemplate from "ember-route-template";
import { i18n } from "discourse-i18n";
import Console from "../../components/docker-manager/console";
import ProgressBar from "../../components/docker-manager/progress-bar";

export default RouteTemplate(
  <template>
    <h2>{{@controller.title}}</h2>

    <ProgressBar @percent={{@controller.upgradeStore.progressPercentage}} />

    {{#if @controller.complete}}
      <p>{{i18n "admin.docker.update_successful"}}</p>
    {{else if @controller.failed}}
      <p>{{i18n "admin.docker.update_error"}}</p>
    {{/if}}

    {{#if @controller.isUpToDate}}
      {{#if @controller.multiUpgrade}}
        <p>{{i18n "admin.docker.everything_up_to_date"}}</p>
      {{else}}
        <p>{{i18n
            "admin.docker.repo_newest_version"
            name=@controller.model.name
          }}</p>
      {{/if}}
    {{else}}
      <div class="upgrade-actions">
        <button
          {{on "click" @controller.start}}
          disabled={{@controller.upgrading}}
          class="btn start-upgrade"
          type="button"
        >
          {{#if @controller.upgrading}}
            {{i18n "admin.docker.updating"}}
          {{else}}
            {{i18n "admin.docker.start_updating"}}
          {{/if}}
        </button>

        {{#if @controller.upgrading}}
          <button
            {{on "click" @controller.resetUpgrade}}
            class="btn unlock"
            type="button"
          >
            {{i18n "admin.docker.reset_update"}}
          </button>
        {{/if}}
      </div>
    {{/if}}

    <Console
      @output={{@controller.upgradeStore.consoleOutput}}
      @followOutput={{true}}
    />
  </template>
);
