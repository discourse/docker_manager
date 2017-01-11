/* global Discourse */

import Ember from "ember";

export default Ember.Controller.extend({
  showBanner: function(){
    if(this.get("bannerDismissed")){
      return false;
    }

    const banner = this.get("banner");
    return banner && banner.length > 0;
  }.property("banner", "bannerDismissed", "banner.@each"),

  appendBannerHtml: function(html){
    const banner = this.get("banner") || [];
    if(banner.indexOf(html) === -1){
      banner.pushObject(html);
    }
    this.set("banner", banner);
  },

  logoUrl: function() {
    return Discourse.getURL("/assets/images/docker-manager-aff8eaea0445c0488c19f8cfd14faa8c2b278924438f19048eacc175d7d134e4.png");
  }.property(),

  returnToSiteUrl: function() {
    return Discourse.getURL("/");
  }.property(),

  backupsUrl: function() {
    return Discourse.getURL("/admin/backups");
  }.property(),

  actions: {
    dismiss: function () {
      this.set("bannerDismissed", true);
    }
  }
});
