class AdministratorsController < SecureGatewayController

  def show
    case
    when (@administrator.present? and @administrator.admin?)
      @object = Administrator.find(params[:id])
    when (@administrator.present? and params[:id].try(:to_i) == @administrator.id)
      @object = @administrator
    else
      head 403
    end
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
      render :status => 403, :text => "Must provide Client Certificate"
      return
    end

    @administrator = Administrator.create(public_key: @clientcert.to_der,
                                          name: params[:name])
    head 201, :location => url_for(@administrator)
  end

  def update
    head 403
  end

end
