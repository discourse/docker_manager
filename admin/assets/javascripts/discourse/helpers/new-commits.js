import { htmlSafe } from "@ember/template";
import I18n from "discourse-i18n";

export default function newCommits(commitsBehind, oldSha, newSha, url) {
  if (!commitsBehind) {
    return "";
  }

  if (parseInt(commitsBehind, 10) === 0) {
    return "";
  }

  const description = I18n.t("admin.docker.commits", {
    count: commitsBehind,
  });

  if (!url) {
    return description;
  }

  const _url = url.substr(0, url.search(/(\.git)?$/));
  return htmlSafe(
    `<a href='${_url}/compare/${oldSha}...${newSha}'>${description}</a>`
  );
}
