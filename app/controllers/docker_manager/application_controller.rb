module DockerManager
  class ApplicationController < ActionController::Base
    helper DockerManager::ApplicationHelper

    include CurrentUser

    before_action :ensure_admin
    protect_from_forgery

    def handle_unverified_request
      super
      clear_current_user
      render plain: "['BAD CSRF']", status: 403
    end

    protected

    def ensure_admin
      return redirect_to '/login' if !current_user
      return render(plain: I18n.t('invalid_access'), status: 404) if !current_user.admin?
    end

  end
end
