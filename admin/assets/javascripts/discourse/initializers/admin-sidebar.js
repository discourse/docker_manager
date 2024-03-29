import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "docker-manager-admin-sidebar",

  initialize() {
    withPluginApi("1.24.0", (api) => {
      api.addAdminSidebarSectionLink("root", {
        name: "admin_upgrade",
        route: "upgrade.index",
        label: "admin.docker.upgrade_tab",
        icon: "rocket",
      });
    });
  },
};
