DockerManager::Engine.routes.draw do
  get "admin/docker", to: redirect("/admin/upgrade"), constraints: AdminConstraint.new
  get "admin/upgrade" => "admin#index", constraints: AdminConstraint.new
  get "admin/docker/repos" => "admin#repos", constraints: AdminConstraint.new
  get "admin/docker/latest" => "admin#latest", constraints: AdminConstraint.new
  get "admin/docker/progress" => "admin#progress", constraints: AdminConstraint.new
  get "admin/docker/ps" => "admin#ps", constraints: AdminConstraint.new
  post "admin/docker/upgrade" => "admin#upgrade", constraints: AdminConstraint.new
  delete "admin/docker/upgrade" => "admin#reset_upgrade", constraints: AdminConstraint.new
  get "admin/docker/runaway_cpu" => "admin#runaway_cpu", constraints: AdminConstraint.new
  get "admin/docker/runaway_mem" => "admin#runaway_mem", constraints: AdminConstraint.new
  get 'admin/docker/csrf' => 'admin#csrf', constraints: AdminConstraint.new
end
