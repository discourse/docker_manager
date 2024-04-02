# frozen_string_literal: true

DockerManager::Engine.routes.draw do
  scope "/admin", constraints: AdminConstraint.new do
    get "/upgrade", to: redirect("/update")
    get "/upgrade/:id", to: redirect("/update/%{id}")
    get "/update" => "admin#index"
    get "/update/:id" => "admin#index"
    get "/docker/repos" => "admin#repos"
    get "/docker/latest" => "admin#latest"
    get "/docker/progress" => "admin#progress"
    get "/docker/ps" => "admin#ps"

    post "/docker/update" => "admin#update"
    delete "/docker/update" => "admin#reset_update"
  end
end
