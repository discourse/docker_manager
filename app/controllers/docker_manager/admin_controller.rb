module DockerManager
  class AdminController < DockerManager::ApplicationController
    layout nil

    def index
      require_dependency 'docker_manager/git_repo'
      @main_repo = DockerManager::GitRepo.new(Rails.root)
    end
  end
end
