import Component from "@glimmer/component";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { bind } from "discourse-common/utils/decorators";

export default class Console extends Component {
  @bind
  scrollToBottom(element) {
    if (this.args.followOutput) {
      element.scrollTop = element.scrollHeight;
    }
  }

  <template>
    <div
      class="console-logs"
      {{didInsert this.scrollToBottom}}
      {{didUpdate this.scrollToBottom @output}}
    >
      {{~@output~}}
    </div>
  </template>
}
