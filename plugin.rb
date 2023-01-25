# frozen_string_literal: true

# name: docker_manager
# about: Docker manager for Discourse image
# version: 1.0.0
# authors: Robin Ward, Sam Saffron
# url: https://github.com/discourse/docker_manager

register_asset "stylesheets/common/docker-manager.scss"

module ::DockerManager
  class Engine < ::Rails::Engine
    engine_name "docker_manager"
    isolate_namespace DockerManager
  end
end

after_initialize do
  Discourse::Application.routes.append do
    mount ::DockerManager::Engine, at: "/"
  end
end
