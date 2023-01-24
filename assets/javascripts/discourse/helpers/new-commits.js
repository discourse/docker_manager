import { helper as buildHelper } from "@ember/component/helper";
import { htmlSafe } from "@ember/template";
import I18n from "I18n";

export default buildHelper(function (params) {
  const [commitsBehind, oldSha, newSha, url] = params;

  if (!commitsBehind) {
    return "";
  }

  if (parseInt(commitsBehind, 10) === 0) {
    return "";
  }

  let description = I18n.t("admin.docker.commits", {
    count: commitsBehind,
  });

  if (!url) {
    return description;
  }

  const _url = url.substr(0, url.search(/(\.git)?$/));
  description = `<a href='${_url}/compare/${oldSha}...${newSha}'>${description}</a>`;

  return new htmlSafe(description);
});
