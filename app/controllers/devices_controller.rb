class DevicesController < SecureGatewayController
  before_action :admin_login

  def show
    # admin_login made sure things were okay, (or returned 403)

    respond_to do |format|
      format.json {
        render
      }
    end
  end
end
