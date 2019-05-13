# frozen_string_literal: true

module DockerManager
  class ApplicationController < ActionController::Base
    helper DockerManager::ApplicationHelper

    include CurrentUser

    protect_from_forgery

    def handle_unverified_request
      unless is_api?
        super
        clear_current_user
        render plain: "['BAD CSRF']", status: 403
      end
    end

  end
end
