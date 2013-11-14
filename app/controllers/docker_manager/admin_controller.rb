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
  end
end
