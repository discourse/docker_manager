# frozen_string_literal: true

module DockerManager::ApplicationHelper
  def discourse_root_url
    Discourse.base_uri
  end

  def long_polling_base_url
    SiteSetting.long_polling_base_url
  end
end
