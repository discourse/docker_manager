export default Ember.Component.extend({
  tagName: "tr",
  href: function() {
    return Discourse.getAppURL("/admin/upgrade");
  }.property()
});
