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

  def create
    if device_params[:eui64]
      @object = Device.find_or_create_by_mac(device_params[:eui64])
      @object.update_attributes(device_params)
    else
      @object = Device.create(device_params)
    end
    if @object
      @object.save
      head 201, :location => url_for(@object)
    else
      head 500
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

  def destroy
    @object = Device.find(params[:id])
    if @object
      @object.deleted = true
      @object.save
    end
  end

  protected

  def device_params
    params.require(:device).permit(:name, :fqdn, :eui64, :idevid, :mud_url, :current_vlan, :wan_enabled, :lan_enabled, :firewall_rules, :deleted, :quaranteed, :device_enabled)
  end

end
