module DockerManager::ApplicationHelper
  def has_uglify_js
    @has_uglify_js ||= `which uglifyjs`.present?
  end
end
