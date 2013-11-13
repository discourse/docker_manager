module DockerManager
  class ApplicationController < ActionController::Base

    include CurrentUser

    before_filter :ensure_admin

    protected

    def ensure_admin
      raise Discourse::InvalidAccess.new unless current_user.admin?
    end

  end
end
