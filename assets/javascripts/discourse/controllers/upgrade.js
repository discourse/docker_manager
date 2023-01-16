import Controller from "@ember/controller";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";

export default class Upgrade extends Controller {
  @tracked banner = [];
  @tracked bannerDismissed = false;

  get showBanner() {
    if (this.bannerDismissed) {
      return false;
    }

    return this.banner?.length > 0;
  }

  appendBannerHtml(html) {
    if (!this.banner.includes(html)) {
      this.banner = [...this.banner, html];
    }
  }

  @action
  dismiss() {
    this.bannerDismissed = true;
  }
}
