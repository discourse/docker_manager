import Component from "@glimmer/component";
import { inject as service } from "@ember/service";

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
}
