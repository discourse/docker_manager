import EmberObject from "@ember/object";
import Discourse from "manager-client/discourse";
import jQuery from "jquery";

const ProcessList = EmberObject.extend({
  output: null,

  refresh() {
    return jQuery
      .ajax(Discourse.getAppURL("/admin/docker/ps"), {
        dataType: "text",
      })
      .then((result) => {
        this.set("output", result);
        return this;
      });
  },
});

export function find() {
  return ProcessList.create().refresh();
}

export default ProcessList;
