import { find } from "discourse/plugins/docker_manager/discourse/models/process-list";
import Route from "@ember/routing/route";

export default Route.extend({
  model: find,
});
