import getURL from "discourse-common/lib/get-url";
import Component from "@ember/component";

export default class extends Component {
  tagName = "tr";

  get href() {
    return getURL("/admin/upgrade");
  }
}
