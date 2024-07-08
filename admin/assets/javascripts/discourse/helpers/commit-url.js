import { htmlSafe } from "@ember/template";

export default function commitUrl(cssClass, version, prettyVersion, url) {
  if (!prettyVersion) {
    return "";
  }

  if (!url) {
    return prettyVersion;
  }

  const repoUrl = url.substr(0, url.search(/(\.git)?$/));
  const description = `<a class='${cssClass} commit-hash' title='${version}' href='${repoUrl}/commit/${version}'>${prettyVersion}</a>`;

  return new htmlSafe(description);
}
