export default {
  resource: "admin",

  map() {
    this.route(
      "upgrade",
      { resetNamespace: true, path: "upgrade" },
      function () {
        this.route("processes");
        this.route("show", { path: "/:id" });
      }
    );
  },
};
