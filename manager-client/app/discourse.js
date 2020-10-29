/* eslint-disable */
import jQuery from "jquery";

function init() {
  const data = JSON.parse(
    document.getElementById("preloaded-data").dataset.preload
  );
  jQuery.extend(Discourse, data);
}

const Discourse = {
  getAppURL(url) {
    if (!this.hasOwnProperty("rootUrl")) {
      init();
    }
    if (!url) return url;

    // if it's a non relative URL, return it.
    if (url !== "/" && !/^\/[^/]/.test(url)) return url;

    if (url.indexOf(this.rootUrl) !== -1) return url;
    if (url[0] !== "/") url = "/" + url;

    return this.rootUrl + url;
  },
};

export default Discourse;

/* eslint-enable */
