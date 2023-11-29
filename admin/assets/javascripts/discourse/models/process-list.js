import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";

export default class ProcessList {
  @tracked output = null;

  async refresh() {
    const result = await ajax("/admin/docker/ps", {
      dataType: "text",
    });

    this.output = result;
  }
}
