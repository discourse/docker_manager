import { htmlSafe } from "@ember/template";

export default function commitUrl(cssClass, version, prettyVersion, url) {
  if (!prettyVersion) {
    return "";
  }

  if (!url) {
    return prettyVersion;
  }

  const repoUrl = url.substr(0, url.search(/(\.git)?$/));
  return htmlSafe(
    `<a class='${cssClass} commit-hash' title='${version}' href='${repoUrl}/commit/${version}'>${prettyVersion}</a>`
  );
}
