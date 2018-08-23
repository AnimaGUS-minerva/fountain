class DevicesController < SecureGatewayController
  before_action :admin_login

  def show
    # admin_login made sure things were okay, (or returned 403)

    @object = Device.find(params[:id])

    respond_to do |format|
      format.json {
        render
      }
    end
  end

  def index

    # what default scope should we use?
    @objects = Device.all

    respond_to do |format|
      format.json {
        render
      }
    end
  end
end
