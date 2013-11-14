DockerManager::Engine.routes.draw do
  get "admin/docker" => "admin#index"
  get "admin/docker/ps" => "admin#ps"
  post "admin/docker/upgrade" => "admin#upgrade"
end
