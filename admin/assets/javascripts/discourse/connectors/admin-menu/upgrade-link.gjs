import Component from "@ember/component";
import { classNames, tagName } from "@ember-decorators/component";
import NavItem from "discourse/components/nav-item";

@tagName("")
@classNames("admin-menu-outlet", "upgrade-link")
export default class UpgradeLink extends Component {
  <template>
    {{#if this.currentUser.admin}}
      <NavItem @route="update" @label="admin.docker.update_tab" />
    {{/if}}
  </template>
}
