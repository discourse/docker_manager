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

Rails.configuration.assets.precompile += ['docker_manager.js']

after_initialize do

  Discourse::Application.routes.append do
    mount ::DockerManager::Engine, at: "/"
  end
end

register_asset "javascripts/admin/templates/version_checks.js.handlebars"
