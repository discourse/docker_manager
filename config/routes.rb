# frozen_string_literal: true

DockerManager::Engine.routes.draw do
  scope "/admin", constraints: AdminConstraint.new do
    get "/upgrade" => "admin#index"
    get "/upgrade/:id" => "admin#index"
    get "/docker/repos" => "admin#repos"
    get "/docker/latest" => "admin#latest"
    get "/docker/progress" => "admin#progress"
    get "/docker/ps" => "admin#ps"

    post "/docker/upgrade" => "admin#upgrade"
    delete "/docker/upgrade" => "admin#reset_upgrade"
  end
end
