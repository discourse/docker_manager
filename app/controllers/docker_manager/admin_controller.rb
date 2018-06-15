require_dependency 'docker_manager/git_repo'
require_dependency 'docker_manager/upgrader'

module DockerManager
  class AdminController < DockerManager::ApplicationController
    layout nil

    def index
      return if Rails.env.development?

      version = File.read('/VERSION') rescue '1.0.0'

      version = Gem::Version.new(version)
      expected_version = Gem::Version.new('2.0.20180613')
      ruby_version = Gem::Version.new(RUBY_VERSION)
      expected_ruby_version = Gem::Version.new('2.5.1')

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
      repo = DockerManager::GitRepo.find(params[:path])
      raise Discourse::NotFound unless repo.present?

      upgrader = Upgrader.new(current_user.id, repo, params[:version])
      render json: {
        progress: {
          logs: upgrader.find_logs,
          percentage: upgrader.last_percentage
        }
      }
    end

    def latest
      repo = DockerManager::GitRepo.find(params[:path])
      raise Discourse::NotFound unless repo.present?

      repo.update_remote! if Rails.env == 'production'

      render json: {
        latest: {
          version: repo.latest_origin_commit,
          commits_behind: repo.commits_behind,
          date: repo.latest_origin_commit_date
        }
      }
    end

    def upgrade
      repo = DockerManager::GitRepo.find(params[:path])
      raise Discourse::NotFound unless repo.present?
      Thread.new do
        upgrader = Upgrader.new(current_user.id, repo, params[:version])
        upgrader.upgrade
      end
      render plain: "OK"
    end

    def reset_upgrade
      repo = DockerManager::GitRepo.find(params[:path])
      raise Discourse::NotFound unless repo.present?

      upgrader = Upgrader.new(current_user.id, repo, params[:version])
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
  end
end
