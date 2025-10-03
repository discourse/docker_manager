# frozen_string_literal: true

require_dependency "docker_manager/git_repo"
require_dependency "docker_manager/upgrader"

module DockerManager
  class AdminController < Admin::AdminController
    requires_plugin PLUGIN_NAME

    def index
    end

    def repos
      repos = DockerManager::GitRepo.find_all
      core_repo = repos.find { |r| r.name == "discourse" }
      core_repo.update_remote! if Rails.env.production?

      repos.map! do |r|
        result = {
          name: r.name,
          path: r.path,
          branch: r.tracking_ref,
          official: Plugin::Metadata::OFFICIAL_PLUGINS.include?(r.name),
        }

        plugin = Discourse.plugins.find { |p| p.path == "#{r.path}/plugin.rb" }
        result[:plugin] = AdminPluginSerializer.new(
          plugin,
          scope: guardian,
          root: false,
        ) if plugin.present?

        result[:fork] = true if result[:official] &&
          !r.url.starts_with?("https://github.com/discourse/")

        result[:id] = r.name.downcase.gsub(/[^a-z]/, "_").gsub(/_+/, "_").sub(/_$/, "")
        result[:version] = r.latest_local_commit
        result[:pretty_version] = r.latest_local_tag_version.presence
        result[:url] = r.url
        if r.upgrading?
          result[:upgrading] = true
          result[:version] = r.upgrade_version
        end

        result
      end

      response = { repos: repos }

      if !Rails.env.development? && !Rails.env.test?
        version =
          begin
            File.read("/VERSION")
          rescue StandardError
            "1.0.0"
          end

        version = Gem::Version.new(version)
        expected_version = Gem::Version.new("2.0.20251003-1437")
        ruby_version = Gem::Version.new(RUBY_VERSION)
        expected_ruby_version = Gem::Version.new("3.2.1")
        min_stable_version = Gem::Version.new("3.0.0")
        min_beta_version = Gem::Version.new("3.1.0.beta1")

        upgrade_image = version < expected_version
        upgrade_ruby = ruby_version < expected_ruby_version
        upgrade_discourse = discourse_upgrade_required?(min_stable_version, min_beta_version)
        missing_core_branch = !core_repo.detached_head? && !core_repo.upstream_branch_exist?

        response[:upgrade_required] = true if upgrade_image || upgrade_ruby || upgrade_discourse ||
          missing_core_branch
      end

      render json: response
    end

    def progress
      repo = AdminController.find_repos(params[:path], upgrading: true)
      return respond_progress if repo.blank?

      upgrader = Upgrader.new(current_user.id, repo, repo_version(repo))
      respond_progress(
        logs: upgrader.find_logs || "",
        percentage: upgrader.last_percentage || 0,
        status: upgrader.last_status || nil,
        repos: Array.wrap(repo).map(&:name),
      )
    end

    def latest
      proc =
        Proc.new do |repo|
          repo.update_remote! if Rails.env.production?
          {
            path: repo.path,
            version: repo.latest_origin_commit,
            pretty_version: repo.latest_origin_tag_version.presence,
            commits_behind: repo.commits_behind,
            date: repo.latest_origin_commit_date,
          }
        end

      if params[:path] == "all"
        return(render json: { repos: DockerManager::GitRepo.find_all.map(&proc) })
      end

      repo = DockerManager::GitRepo.find(params[:path])
      raise Discourse::NotFound if repo.blank?

      render json: { latest: proc.call(repo) }
    end

    def upgrade
      repo = AdminController.find_repos(params[:path])
      raise Discourse::NotFound if repo.blank?

      script_path =
        File.expand_path(File.join(__dir__, "../../../scripts/docker_manager_upgrade.rb"))

      env_vars = {
        "UPGRADE_USER_ID" => current_user.id.to_s,
        "UPGRADE_PATH" => params[:path].to_s,
        "UPGRADE_REPO_VERSION" => repo_version(repo).to_s,
        "RAILS_ENV" => Rails.env,
      }
      %w[http_proxy https_proxy no_proxy HTTP_PROXY HTTPS_PROXY NO_PROXY].each do |p|
        env_vars[p] = ENV[p] if !ENV[p].nil?
      end
      pid = spawn(env_vars, "bundle exec rails runner #{script_path}")
      Process.detach(pid)

      render plain: "OK"
    end

    def reset_upgrade
      repo = AdminController.find_repos(params[:path], upgrading: true)
      raise Discourse::NotFound if repo.blank?

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

    def self.find_repos(path, upgrading: false)
      return DockerManager::GitRepo.find(path) if path != "all"

      DockerManager::GitRepo.find_all.select do |repo|
        if upgrading
          repo.upgrading?
        else
          !repo.upgrading? && (repo.latest_local_commit != repo.latest_origin_commit)
        end
      end
    end

    private

    def respond_progress(logs: "", percentage: 0, status: nil, repos: nil)
      progress = { logs: logs, percentage: percentage, status: status, repos: repos }

      render json: { progress: progress }
    end

    def repo_version(repo)
      if repo.is_a?(Array) && params[:version].blank?
        repo.map(&:latest_local_commit).join(", ")
      else
        params[:version]
      end
    end

    def discourse_upgrade_required?(min_stable_version, min_beta_version)
      tracking_stable = Discourse::VERSION::PRE.nil?
      discourse_version = Gem::Version.new(Discourse::VERSION::STRING)

      target_version = tracking_stable ? min_stable_version : min_beta_version

      discourse_version < target_version
    end
  end
end
