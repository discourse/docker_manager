import Ember from 'ember';

export default Ember.Handlebars.makeBoundHelper(function(sha1, url, branch) {
  if (Ember.isNone(url)) { return; }
  if (Ember.isNone(branch)) {
    return new Ember.Handlebars.SafeString("(<a href='" + url + "' target='_new'>" + sha1 + "</a>)");
  }

  var _url = url.substr(0, url.indexOf('.git'));
  var _branch = (branch.indexOf('/') !== -1) ? branch.split('/')[1] : branch;
  return new Ember.Handlebars.SafeString("(<a href='" + _url + "/compare/" +
                                         sha1 + "..." + _branch + "' target='_new'>" + sha1 + "</a>)");
});
