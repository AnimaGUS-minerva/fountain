class SecureGatewayController < ApplicationController
  before_action :ssl_authenticator_lookup

  #protected
  def ssl_authenticator_lookup
    @peer_cert = request.env["SSL_CLIENT_CERT"] || request.env["rack.peer_cert"]
    if @peer_cert
      @clientcert =  OpenSSL::X509::Certificate.new(@peer_cert)

      @administrator = Administrator.find_by_public_key(@clientcert.to_der)
    end
  end

  def ssl_login
    ssl_authenticator_lookup
    unless @administrator
      head 401
    end
  end

end
