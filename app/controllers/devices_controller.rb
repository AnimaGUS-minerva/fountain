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

  def update
    @object = Device.find(params[:id])

    if @object.update_attributes(device_params)
      @object.save!
      head 200
    else
      head 500
    end

  end

  protected

  def device_params
    params.require(:device).permit(:name, :fqdn, :eui64, :idevid, :mud_url, :current_vlan, :wan_enabled, :lan_enabled, :firewall_rules)
  end


end
