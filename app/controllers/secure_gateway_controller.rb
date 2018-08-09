class SecureGatewayController < ApplicationController
  before_action :ssl_login

  #protected
  def ssl_login
    if request.env["SSL_CLIENT_CERT"]
      clientcert_pem = request.env["SSL_CLIENT_CERT"]
      clientcert =  OpenSSL::X509::Certificate.new(clientcert_pem)

      @administrator = Administrator.find_by_public_key(clientcert.to_der)
    end
    unless @administrator
      head 401
    end
  end

end
