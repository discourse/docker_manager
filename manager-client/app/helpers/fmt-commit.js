import Ember from 'ember';

export default Ember.Helper.helper(function(params) {
  const [sha1, url, branch] = params;

  if (Ember.isNone(url)) { return; }
  if (Ember.isNone(branch)) {
    return new Ember.String.htmlSafe("(<a href='" + url + "'>" + sha1 + "</a>)");
  }

  var _url = url.substr(0, url.search(/(\.git)?$/));
  var _branch = (branch.indexOf('/') !== -1) ? branch.split('/')[1] : branch;
  return new Ember.String.htmlSafe("(<a href='" + _url + "/compare/" + sha1 + "..." + _branch + "'>" + sha1 + "</a>)");
});
