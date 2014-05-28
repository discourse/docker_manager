DockerManager::Engine.routes.draw do
  get "admin/docker" => "admin#index"
  get "admin/docker/repos" => "admin#repos"
  get "admin/docker/latest" => "admin#latest"
  get "admin/docker/progress" => "admin#progress"
  get "admin/docker/ps" => "admin#ps"
  post "admin/docker/upgrade" => "admin#upgrade"
  delete "admin/docker/upgrade" => "admin#reset_upgrade"
  get "admin/docker/runaway_cpu" => "admin#runaway_cpu"
  get "admin/docker/runaway_mem" => "admin#runaway_mem"
  get 'admin/docker/csrf' => 'admin#csrf'
end
