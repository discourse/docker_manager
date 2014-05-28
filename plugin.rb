# name: docker_manager
# about: Docker manager for Discourse image
# version: 0.1
# authors: Sam Saffron

module ::DockerManager
  class Engine < ::Rails::Engine
    engine_name "docker_manager"
    isolate_namespace DockerManager
  end
end

Rails.configuration.assets.precompile += ['docker-manager-app.js', 'docker-manager-app.css', 'docker-manager-config.js', 'docker-manager-vendor.js', 'images/docker-manager.png']

after_initialize do
  Discourse::Application.routes.append do
    mount ::DockerManager::Engine, at: "/"
  end
end

register_asset "javascripts/upgrade-header.js.handlebars"
