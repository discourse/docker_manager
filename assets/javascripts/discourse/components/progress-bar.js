import Component from "@ember/component";
import { computed } from "@ember/object";
import { htmlSafe } from "@ember/template";

export default Component.extend({
  tagName: "",

  active: computed("percent", function () {
    return parseInt(this.get("percent"), 10) !== 100;
  }),

  barStyle: computed("percent", function () {
    let percent = parseInt(this.get("percent"), 10);
    if (percent > 0) {
      if (percent > 100) {
        percent = 100;
      }
      return htmlSafe("width: " + this.get("percent") + "%");
    }

    return htmlSafe("");
  }),
});
