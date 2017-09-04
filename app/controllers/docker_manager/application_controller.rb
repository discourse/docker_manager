module DockerManager
  class ApplicationController < ActionController::Base

    helper DockerManager::ApplicationHelper

    include CurrentUser

    before_action :ensure_admin
    protect_from_forgery

    def handle_unverified_request
      super
      clear_current_user
      render text: "['BAD CSRF']", status: 403
    end

    protected

    def ensure_admin
      raise Discourse::InvalidAccess.new unless current_user && current_user.admin?
    end

  end
end
