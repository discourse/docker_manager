import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "docker-manager-admin-sidebar",

  initialize() {
    withPluginApi("1.24.0", (api) => {
      api.addAdminSidebarSectionLink("root", {
        name: "admin_upgrade",
        route: "update.index",
        label: "admin.docker.update_tab",
        icon: "rocket",
      });
    });
  },
};
