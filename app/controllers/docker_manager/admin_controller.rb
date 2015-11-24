require_dependency 'docker_manager/git_repo'
require_dependency 'docker_manager/upgrader'

module DockerManager
  class AdminController < DockerManager::ApplicationController
    layout nil

    def index
      version = File.read('/VERSION') rescue '1.0.0'
      if version == '1.0.0'
        version = '1.0.13' if File.exist?('/usr/local/lib/libpng16.so.16.19.0')
      end

      version = Gem::Version.new(version)
      expected_version = Gem::Version.new('1.0.13')

      unless version < expected_version

        render text: <<HTML
<html><head></head><body>
<h2>You are running an old version of the Discourse image.<h2>
<p>
Upgraded via the web UI are disabled until you upgrade the image.
</p>
<p>
To do so log in to your server using SSH and run:
</p>

<pre>
cd /var/discourse
git pull
./launcher rebuild app
</pre>
<p>
<a href='https://meta.discourse.org/t/how-do-i-update-my-docker-image-to-latest/23325'>More info on our support site</a>
</p>
</body>
</html>
HTML
      else
        render
      end
    end

    def repos
      repos = [DockerManager::GitRepo.new(Rails.root.to_s, 'discourse')]
      Discourse.plugins.each do |p|
        repos << DockerManager::GitRepo.new(File.dirname(p.path), p.name)
      end
      repos.map! do |r|
        result = {name: r.name, path: r.path, branch: r.branch }
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

      render json: {repos: repos}
    end

    def progress
      repo = DockerManager::GitRepo.new(params[:path])
      upgrader = Upgrader.new(current_user.id, repo, params[:version])
      render json: {progress: {logs: upgrader.find_logs, percentage: upgrader.last_percentage } }
    end

    def latest
      repo = DockerManager::GitRepo.new(params[:path])
      repo.update! if Rails.env == 'production'

      render json: {latest: {version: repo.latest_origin_commit,
                             commits_behind: repo.commits_behind,
                             date: repo.latest_origin_commit_date } }
    end

    def upgrade
      repo = DockerManager::GitRepo.new(params[:path])
      Thread.new do
        upgrader = Upgrader.new(current_user.id, repo, params[:version])
        upgrader.upgrade
      end
      render text: "OK"
    end

    def reset_upgrade
      repo = DockerManager::GitRepo.new(params[:path])
      upgrader = Upgrader.new(current_user.id, repo, params[:version])
      upgrader.reset!
      render text: "OK"
    end

    def ps
      # Normally we don't run on OSX but this is useful for debugging
      if RUBY_PLATFORM =~ /darwin/
        ps_output = `ps aux -m`
      else
        ps_output = `ps aux --sort -rss`
      end
      render text: ps_output
    end

    def runaway_cpu
      Thread.new do
        a = 1
        while true
         a += 1
        end
      end
      render text: "Killing CPU on #{Process.pid}"
    end

    def runaway_mem
      Thread.new do
        a = []
        while true
          a << Array.new(50_000_000/8)
          sleep 30
        end
      end
      render text: "Leaking memory on #{Process.pid}"
    end

  end
end
