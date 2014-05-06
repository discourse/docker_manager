export default Em.Handlebars.makeBoundHelper(function(dt) {
  if (Em.isEmpty(dt)) {
    return new Handlebars.SafeString("&mdash;");
  }

  return moment(dt).fromNow();
});
