module DockerManager
  class AdminController < DockerManager::ApplicationController
    layout nil

    def index
      require_dependency 'docker_manager/git_repo'
      @main_repo = DockerManager::GitRepo.new(Rails.root)
    end

    def upgrade
      require_dependency 'docker_manager/upgrader'
      Thread.new do
        Upgrader.upgrade(current_user.id, params[:path])
      end
      render text: "OK"
    end

    def ps
      render text: `ps aux --sort -rss`
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
