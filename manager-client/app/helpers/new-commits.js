import Ember from "ember";

export default Ember.Helper.helper(function(params) {
  const [commitsBehind, oldSha, newSha, url] = params;

  if (parseInt(commitsBehind) === 0) {
    return "";
  }

  let description = `${commitsBehind} new commit${
    commitsBehind === 1 ? "" : "s"
  }`;

  if (Ember.isNone(url)) {
    return description;
  }

  var _url = url.substr(0, url.search(/(\.git)?$/));
  description = `<a href='${_url}/compare/${oldSha}..${newSha}'>${description}</a>`;

  return new Ember.String.htmlSafe(description);
});
