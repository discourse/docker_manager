import { helper as buildHelper } from "@ember/component/helper";
import { htmlSafe } from "@ember/template";

export default buildHelper(function (params) {
  const [_class, version, prettyVersion, url] = params;

  if (!prettyVersion) {
    return "";
  }

  if (!url) {
    return prettyVersion;
  }

  const repoUrl = url.substr(0, url.search(/(\.git)?$/));
  const description = `<a class='${_class} commit-hash' title='${version}' href='${_url}/commit/${version}'>${prettyVersion}</a>`;

  return new htmlSafe(description);
});
