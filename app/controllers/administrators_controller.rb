class AdministratorsController < SecureGatewayController

  def index
    return unless admin_login

    @objects = Administrator.all

    respond_to do |format|
      format.json
    end
  end

  def show
    ssl_login
    return unless @administrator
    lookup_permitted_object
    return unless @object

    respond_to do |format|
      format.json {
        render
      }
    end
  end

  # create is generally called when a new administrator needs to be
  # setup.  While it accepts a name
  def create
    if @administrator
      # does not seem to be a new admin, just return created message
      # again.
      head 201, :location => url_for(@administrator)
      return
    end

    # validate parameters here manually as it is somewhat special.
    unless @peer_cert
      # 403 = Forbidden
      render :status => :forbidden, :plain => "Must provide Client Certificate"
      return
    end

    @administrator = Administrator.create_from_certificate(@clientcert, params[:name])

    # if TOFU and first admin, set the administrator flag to true.
    if ($ENABLE_TOFU and Administrator.count == 1)
      @administrator.admin!
    end

    head 201, :location => url_for(@administrator)
  end

  # must be logged in to update.
  def update
    return unless ssl_login
    return unless lookup_permitted_object

    case
    when (@administrator.present? and @administrator.admin?)
      @object.update(administrator_params)
    when @object.nil?
      return
    else
      @object.update(mortal_params)
    end
    head 200
  end

  protected

  def administrator_params
    params.require(:administrator).permit(:admin, :enabled, :name,
                                          :prospective, :public_key,
                                          :previous_public_key)
  end
  def mortal_params
    params.require(:administrator).permit(:name)
  end

  def lookup_permitted_object
    case
    when (@administrator.present? and @administrator.admin?)
      @object = Administrator.find(params[:id])
    when (@administrator.present? and params[:id].try(:to_i) == @administrator.id)
      @object = @administrator
    else
      head 403
      return false
    end
  end

end
