import Component from "@glimmer/component";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import i18n from "discourse-common/helpers/i18n";

export default class UpgradeNotice extends Component {
  @service currentUser;

  <template>
    {{#if this.currentUser.admin}}
      {{#unless @versionCheck.upToDate}}
        <div class="upgrades-banner">
          {{i18n "admin.docker.outdated_notice"}}

          <LinkTo @route="update">
            {{i18n "admin.docker.perform_update"}}
          </LinkTo>
        </div>
      {{/unless}}
    {{/if}}
  </template>
}
