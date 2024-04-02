export default {
  resource: "admin",

  map() {
    this.route("update", { resetNamespace: true }, function () {
      this.route("processes");
      this.route("show", { path: "/:id" });
    });
  },
};
