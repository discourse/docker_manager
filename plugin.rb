# frozen_string_literal: true

# name: docker_manager
# about: Docker manager for Discourse image
# version: 0.1
# authors: Robin Ward, Sam Saffron
# url: https://github.com/discourse/docker_manager

register_asset "stylesheets/common/docker-manager.scss"

module ::DockerManager
  # should be automatic, but something is weird
  load File.expand_path(File.dirname(__FILE__)) +
         "/app/helpers/application_helper.rb"

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
