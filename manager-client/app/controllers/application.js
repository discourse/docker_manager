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
    return Discourse.getURL("/assets/images/docker-manager-ea64623b074c8ec2b0303bae846e21e6.png");
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
