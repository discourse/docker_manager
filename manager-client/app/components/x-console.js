/* eslint-disable */

import Component from "@ember/component";
import { observer } from "@ember/object";
import { scheduleOnce } from "@ember/runloop";

export default Component.extend({
  classNameBindings: [":logs"],

  _outputChanged: observer("output", function () {
    scheduleOnce("afterRender", this, "_scrollBottom");
  }),

  _scrollBottom() {
    if (this.get("followOutput")) {
      this.$().scrollTop(this.$()[0].scrollHeight);
    }
  },

  didInsertElement() {
    this._super(...arguments);
    this._scrollBottom();
  },
});

/* eslint-enable */
