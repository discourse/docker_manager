import { find } from "manager-client/models/process-list";
import Route from "@ember/routing/route";

export default Route.extend({
  model: find
});
