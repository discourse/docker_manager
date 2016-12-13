export default Ember.Component.extend({
  tagName: "tr",
  href: function() {
    return Discourse.getURL("/admin/upgrade");
  }.property()
});
