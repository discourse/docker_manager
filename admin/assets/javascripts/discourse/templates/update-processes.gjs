import RouteTemplate from "ember-route-template";
import Console from "../components/docker-manager/console";

export default RouteTemplate(
  <template><Console @output={{@controller.model.output}} /></template>
);
