DockerManager::Engine.routes.draw do
  get "admin/docker" => "admin#index"
  get "admin/docker/ps" => "admin#ps"
  post "admin/docker/upgrade" => "admin#upgrade"
  get "admin/docker/runaway_cpu" => "admin#runaway_cpu"
  get "admin/docker/runaway_mem" => "admin#runaway_mem"
end
