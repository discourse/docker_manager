# name: docker_manager
# about: Docker manager for Discourse image
# version: 0.1
# authors: Robin Ward, Sam Saffron


module ::DockerManager
  # should be automatic, but something is weird
  load File.expand_path(File.dirname(__FILE__)) << '/app/helpers/application_helper.rb'
  class Engine < ::Rails::Engine
    engine_name "docker_manager"
    isolate_namespace DockerManager
  end
end

Rails.configuration.assets.precompile += ['docker-manager-app.js', 'docker-manager-app.css', 'docker-manager-vendor.js', 'docker-manager-vendor.css', 'images/docker-manager.png']

after_initialize do
  Discourse::Application.routes.append do
    mount ::DockerManager::Engine, at: "/"
  end
end

register_asset "javascripts/upgrade-header.js.handlebars"
