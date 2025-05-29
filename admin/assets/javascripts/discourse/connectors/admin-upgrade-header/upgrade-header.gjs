import Component from "@ember/component";
import { classNames, tagName } from "@ember-decorators/component";
import UpgradeNotice from "../../components/docker-manager/upgrade-notice";

@tagName("")
@classNames("admin-upgrade-header-outlet", "upgrade-header")
export default class UpgradeHeader extends Component {
  <template><UpgradeNotice @versionCheck={{@outletArgs.versionCheck}} /></template>
}
