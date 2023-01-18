import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";

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
}
