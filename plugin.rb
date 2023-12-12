# frozen_string_literal: true

# name: docker_manager
# about: Provides basic monitoring and upgrade facilities to sites using discourse_docker.
# meta_topic_id: 12655
# version: 1.0.0
# authors: Robin Ward, Sam Saffron
# url: https://github.com/discourse/docker_manager

hide_plugin

register_asset "stylesheets/common/docker-manager.scss"

module ::DockerManager
  class Engine < ::Rails::Engine
    engine_name "docker_manager"
    isolate_namespace DockerManager
  end
end

after_initialize { Discourse::Application.routes.append { mount ::DockerManager::Engine, at: "/" } }
