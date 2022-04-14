import Discourse from "manager-client/discourse";
import Controller from "@ember/controller";
import { computed } from "@ember/object";

export default Controller.extend({
  showBanner: computed("banner", "bannerDismissed", "banner.[]", function() {
    if (this.get("bannerDismissed")) {
      return false;
    }

    const banner = this.get("banner");
    return banner && banner.length > 0;
  }),

  appendBannerHtml(html) {
    const banner = this.get("banner") || [];
    if (banner.indexOf(html) === -1) {
      banner.pushObject(html);
    }
    this.set("banner", banner);
  },

  logoUrl: computed(function() {
    return Discourse.logoUrl;
  }),

  returnToSiteUrl: computed(function() {
    return Discourse.getAppURL("/");
  }),

  backupsUrl: computed(function() {
    return Discourse.getAppURL("/admin/backups");
  }),

  actions: {
    dismiss() {
      this.set("bannerDismissed", true);
    }
  }
});
