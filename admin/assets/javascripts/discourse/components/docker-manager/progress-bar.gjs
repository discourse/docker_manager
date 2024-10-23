import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";
import concatClass from "discourse/helpers/concat-class";

export default class ProgressBar extends Component {
  get active() {
    return parseInt(this.args.percent, 10) !== 100;
  }

  get barStyle() {
    let percent = parseInt(this.args.percent, 10);

    if (percent > 100) {
      percent = 100;
    }

    return htmlSafe(`width: ${percent}%`);
  }

  <template>
    <div class={{concatClass "progress-bar" (if this.active "active")}}>
      <div class="progress-bar-inner" style={{this.barStyle}}></div>
    </div>
  </template>
}
