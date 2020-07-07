import getURL from "discourse-common/lib/get-url";

export default Ember.Component.extend({
  tagName: "tr",
  href: function() {
    return getURL("/admin/upgrade");
  }.property()
});
