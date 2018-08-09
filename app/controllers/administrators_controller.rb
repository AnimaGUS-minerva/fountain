class AdministratorsController < SecureGatewayController

  def show
    render json: {:hello => "there"}
  end

end
