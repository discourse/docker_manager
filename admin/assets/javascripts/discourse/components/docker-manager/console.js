import Component from "@glimmer/component";
import { bind } from "discourse-common/utils/decorators";

export default class Console extends Component {
  @bind
  scrollToBottom(element) {
    if (this.args.followOutput) {
      element.scrollTop = element.scrollHeight;
    }
  }
}
