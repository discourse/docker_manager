import Component from "@glimmer/component";
import { bind } from "discourse-common/utils/decorators";

export default class Console extends Component {
  @bind
  scrollToBottom() {
    if (this.args.followOutput) {
      const element = document.querySelector(".console-logs");
      element.scrollTop = element.scrollHeight;
    }
  }
}
