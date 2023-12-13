import { tracked } from "@glimmer/tracking";
import Controller from "@ember/controller";
import { action } from "@ember/object";
import { TrackedArray } from "@ember-compat/tracked-built-ins";

export default class Upgrade extends Controller {
  @tracked banner = new TrackedArray([]);
  @tracked bannerDismissed = false;

  get showBanner() {
    if (this.bannerDismissed) {
      return false;
    }

    return this.banner?.length > 0;
  }

  appendBannerHtml(html) {
    if (!this.banner.includes(html)) {
      this.banner.push(html);
    }
  }

  @action
  dismiss() {
    this.bannerDismissed = true;
  }
}
