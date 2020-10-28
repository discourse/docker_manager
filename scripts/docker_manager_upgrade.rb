# frozen_string_literal: true

fork do
  require_relative '../lib/docker_manager/upgrader.rb'

  user_id = ENV['UPGRADE_USER_ID'].to_i
  path = ENV['UPGRADE_PATH']
  repo_version = ENV['UPGRADE_REPO_VERSION']
  raise "user_id is required" if user_id <= 0
  raise "path is required" if path.blank?

  repo = DockerManager::AdminController.find_repos(path)
  raise "No such repo" unless repo.present?

  DockerManager::Upgrader.new(user_id, repo, repo_version).upgrade
end
