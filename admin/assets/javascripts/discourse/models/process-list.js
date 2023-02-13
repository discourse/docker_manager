import { ajax } from "discourse/lib/ajax";
import { tracked } from "@glimmer/tracking";

export default class ProcessList {
  @tracked output = null;

  async refresh() {
    const result = await ajax("/admin/docker/ps", {
      dataType: "text",
    });

    this.output = result;
  }
}
