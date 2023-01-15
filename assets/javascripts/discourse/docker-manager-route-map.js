export default {
  resource: "admin",

  map() {
    this.route("docker-manager", { resetNamespace: true }, function () {
      this.route("processes");
      this.route("upgrade", { path: "/upgrade/:id" });
    });
  },
};
