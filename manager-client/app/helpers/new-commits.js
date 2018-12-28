import { helper as buildHelper } from '@ember/component/helper';
import { isNone } from '@ember/utils';
import { htmlSafe } from '@ember/template';

export default buildHelper(function(params) {
  const [commitsBehind, oldSha, newSha, url] = params;

  if (parseInt(commitsBehind) === 0) {
    return "";
  }

  let description = `${commitsBehind} new commit${
    commitsBehind === 1 ? "" : "s"
  }`;

  if (isNone(url)) {
    return description;
  }

  const _url = url.substr(0, url.search(/(\.git)?$/));
  description = `<a href='${_url}/compare/${oldSha}...${newSha}'>${description}</a>`;

  return new htmlSafe(description);
});
