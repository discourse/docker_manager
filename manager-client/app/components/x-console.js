import Component from "@ember/component";
import { scheduleOnce } from "@ember/runloop";

export default Component.extend({
  classNameBindings: [":logs"],

  didReceiveAttrs() {
    this._super(...arguments);

    if (this.get("followOutput")) {
      scheduleOnce("afterRender", this, "_scrollBottom");
    }
  },
  
  _scrollBottom() {
    this.$().scrollTop(this.$()[0].scrollHeight);
  }
});
