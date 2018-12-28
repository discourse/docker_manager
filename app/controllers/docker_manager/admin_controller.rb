require_dependency 'docker_manager/git_repo'
require_dependency 'docker_manager/upgrader'

module DockerManager
  class AdminController < DockerManager::ApplicationController
    layout nil

    def index
      return if Rails.env.development?

      version = File.read('/VERSION') rescue '1.0.0'

      version = Gem::Version.new(version)
      expected_version = Gem::Version.new('2.0.20181031')
      ruby_version = Gem::Version.new(RUBY_VERSION)
      expected_ruby_version = Gem::Version.new('2.5.2')

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

      pid = fork do
        exit if fork
        Process.setsid
        exit if fork
        Upgrader.new(current_user.id, repo, repo_version(repo)).upgrade
      end

      Process.waitpid(pid)

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
      params[:path] == "all"
    end

    def find_repos(path, upgrading: false, all: false)
      unless all_repos?
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

    def repo_version(repo)
      return repo.is_a?(Array) && params[:version].blank? ? concat_repos_versions(repo) : params[:version]
    end

    def concat_repos_versions(repos)
      repos.map(&:latest_local_commit).join(", ")
    end
  end
end
