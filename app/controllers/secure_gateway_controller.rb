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
    unless @administrator
      ssl_authenticator_lookup
    end
    unless @administrator
      head 401
      return false
    end
  end

  def admin_login
    return false unless ssl_login
    unless @administrator.admin?
      head 401
      return false
    end
    true
  end

end
