import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";

export default class RepoStatus extends Component {
  @service router;

  get upgradeDisabled() {
    if (this.args.upgradingRepo) {
      return true;
    }

    if (!this.args.managerRepo) {
      return false;
    }

    return (
      !this.args.managerRepo.upToDate &&
      this.args.managerRepo !== this.args.repo
    );
  }

  get officialRepoBadge() {
    if (this.args.repo.fork) {
      return "exclamation-circle";
    } else if (this.args.repo.official) {
      return "check-circle";
    }
  }

  get officialRepoBadgeTitle() {
    if (this.args.repo.fork) {
      return "Forked Official Plugin";
    } else if (this.args.repo.official) {
      return "Official Plugin";
    }
  }

  get upgradeButtonLabel() {
    if (this.args.repo.upgrading) {
      return "Currently Upgrading…";
    } else {
      return "Upgrade";
    }
  }

  @action
  upgrade() {
    this.router.transitionTo("upgrade.show", this.args.repo);
  }
}
