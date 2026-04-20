# frozen_string_literal: true

require_relative "../docker_manager/web_server_adapter"

namespace :docker_manager do
  desc "Clear Redis flags that would otherwise leave the web upgrade UI stuck. Invoked by discourse_docker after a full rebuild."
  task stop_all_upgrades: :environment do
    RailsMultisite::ConnectionManagement.each_connection do
      Discourse.redis.scan_each(match: "upgrade:*") { |key| Discourse.redis.del(key) }
      Discourse.redis.del(DockerManager::WebServerAdapter::RESTART_FLAG_KEY)
    end
  end
end
