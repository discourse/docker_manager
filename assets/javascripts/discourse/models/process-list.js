import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";

const ProcessList = EmberObject.extend({
  output: null,

  refresh() {
    return ajax("/admin/docker/ps", {
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
