export default Em.Handlebars.makeBoundHelper(function(sha1, url) {
  if (Em.isNone(url)) { return; }
  return new Em.Handlebars.SafeString("(<a href='" + url + "'>" + sha1 + "</a>)");
});
