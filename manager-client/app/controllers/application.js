/* global Discourse */

import Controller from '@ember/controller';
import { computed } from "@ember/object";

export default Controller.extend({
  showBanner: computed("banner", "bannerDismissed", "banner.[]",  function(){
    if(this.get("bannerDismissed")){
      return false;
    }

    const banner = this.get("banner");
    return banner && banner.length > 0;
  }),

  appendBannerHtml(html) {
    const banner = this.get("banner") || [];
    if(banner.indexOf(html) === -1){
      banner.pushObject(html);
    }
    this.set("banner", banner);
  },

  logoUrl: computed(function() {
    return Discourse.getURL("/assets/images/docker-manager-aff8eaea0445c0488c19f8cfd14faa8c2b278924438f19048eacc175d7d134e4.png");
  }),

  returnToSiteUrl: computed(function() {
    return Discourse.getURL("/");
  }),

  backupsUrl: computed(function() {
    return Discourse.getURL("/admin/backups");
  }),

  actions: {
    dismiss() {
      this.set("bannerDismissed", true);
    }
  }
});
