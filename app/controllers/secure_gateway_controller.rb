class SecureGatewayController < ApplicationController
  before_action :ssl_login

  #protected
  def ssl_login
    @peer_cert = request.env["SSL_CLIENT_CERT"] || request.env["rack.peer_cert"]
    if @peer_cert
      @clientcert =  OpenSSL::X509::Certificate.new(@peer_cert)

      @administrator = Administrator.find_by_public_key(@clientcert.to_der)
    end
    unless @administrator
      head 401
    end
  end

end
