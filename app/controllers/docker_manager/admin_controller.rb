# frozen_string_literal: true

require_dependency 'docker_manager/git_repo'
require_dependency 'docker_manager/upgrader'

module DockerManager
  class AdminController < DockerManager::ApplicationController
    layout nil

    def index
      return if Rails.env.development?

      version = File.read('/VERSION') rescue '1.0.0'

      version = Gem::Version.new(version)
      expected_version = Gem::Version.new('2.0.20220128-1817')
      ruby_version = Gem::Version.new(RUBY_VERSION)
      expected_ruby_version = Gem::Version.new('2.7.6')

      if (version < expected_version) || (ruby_version < expected_ruby_version)
        render 'upgrade_required', layout: false
      else
        render
      end
    end

    def repos
      repos = DockerManager::GitRepo.find_all
      repos.map! do |r|
        result = {
          name: r.name,
          path: r.path,
          branch: r.branch,
          official: Plugin::Metadata::OFFICIAL_PLUGINS.include?(r.name)
        }

        result[:fork] = true if result[:official] && !r.url.starts_with?("https://github.com/discourse/")

        if r.valid?
          result[:id] = r.name.downcase.gsub(/[^a-z]/, '_').gsub(/_+/, '_').sub(/_$/, '')
          result[:version] = r.latest_local_commit
          result[:pretty_version] = r.latest_local_tag_version.presence
          result[:url] = r.url
          if r.upgrading?
            result[:upgrading] = true
            result[:version] = r.upgrade_version
          end
        end
        result
      end

      render json: { repos: repos }
    end

    def progress
      repo = find_repos(params[:path], upgrading: true)
      return respond_progress if repo.blank?

      upgrader = Upgrader.new(current_user.id, repo, repo_version(repo))
      respond_progress(logs: upgrader.find_logs, percentage: upgrader.last_percentage)
    end

    def latest
      proc = Proc.new do |repo|
        repo.update_remote! if Rails.env == 'production'
        {
          path: repo.path,
          version: repo.latest_origin_commit,
          pretty_version: repo.latest_origin_tag_version.presence,
          commits_behind: repo.commits_behind,
          date: repo.latest_origin_commit_date
        }
      end

      if all_repos?
        return render json: {
          repos: DockerManager::GitRepo.find_all.map(&proc)
        }
      end

      repo = DockerManager::GitRepo.find(params[:path])
      raise Discourse::NotFound unless repo.present?

      render json: {
        latest: proc.call(repo)
      }
    end

    def upgrade
      repo = find_repos(params[:path])
      raise Discourse::NotFound unless repo.present?
      script_path = File.expand_path(File.join(__dir__, '../../../scripts/docker_manager_upgrade.rb'))

      env_vars = {
          'UPGRADE_USER_ID' => current_user.id.to_s,
          'UPGRADE_PATH' => params[:path].to_s,
          'UPGRADE_REPO_VERSION' => repo_version(repo).to_s,
          'RAILS_ENV' => Rails.env
      }
      ["http_proxy", "https_proxy", "no_proxy", "HTTP_PROXY", "HTTPS_PROXY", "NO_PROXY"].each do |p|
        env_vars[p] = ENV[p] if ! ENV[p].nil?
      end
      pid = spawn(
        env_vars,
        "bundle exec rails runner #{script_path}"
      )
      Process.detach(pid)
      render plain: "OK"
    end

    def reset_upgrade
      repo = find_repos(params[:path], upgrading: true)
      raise Discourse::NotFound unless repo.present?

      upgrader = Upgrader.new(current_user.id, repo, repo_version(repo))
      upgrader.reset!
      render plain: "OK"
    end

    def ps
      # Normally we don't run on OSX but this is useful for debugging
      if RUBY_PLATFORM =~ /darwin/
        ps_output = `ps aux -m`
      else
        ps_output = `ps aux --sort -rss`
      end
      render plain: ps_output
    end

    def self.all_repos?(path)
      path == "all"
    end

    def self.find_repos(path, upgrading: false, all: false)
      unless all_repos?(path)
        return DockerManager::GitRepo.find(path)
      end

      repos = DockerManager::GitRepo.find_all
      return repos if all

      repos.select do |repo|
        if upgrading
          repo.upgrading?
        else
          !repo.upgrading? && (repo.latest_local_commit != repo.latest_origin_commit)
        end
      end
    end

    private

    def respond_progress(logs: nil, percentage: nil)
      render json: {
        progress: {
          logs: logs,
          percentage: percentage
        }
      }
    end

    def all_repos?
      self.class.all_repos?(params[:path])
    end

    def find_repos(path, upgrading: false, all: false)
      self.class.find_repos(path, upgrading: upgrading, all: all)
    end

    def repo_version(repo)
      repo.is_a?(Array) && params[:version].blank? ? concat_repos_versions(repo) : params[:version]
    end

    def concat_repos_versions(repos)
      repos.map(&:latest_local_commit).join(", ")
    end
  end
end
