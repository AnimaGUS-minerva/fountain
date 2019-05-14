class SecureGatewayController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :ssl_authenticator_lookup

  #protected
  def ssl_authenticator_lookup
    clientname = "unknown"
    @peer_cert = request.env["SSL_CLIENT_CERT"] || request.env["rack.peer_cert"]
    if @peer_cert
      @clientcert =  OpenSSL::X509::Certificate.new(@peer_cert)
      if @clientcert
        clientname = sprintf("DN: %s, id: unknown", @clientcert.subject.to_s)
      end

      @administrator = Administrator.find_by_cert(@clientcert)
      if @administrator
        clientname = sprintf("DN: %s, id: %d", @clientcert.subject.to_s, @administrator.id)
      end
    end

    logger.info "Connection from #{clientname}"
  end

  def ssl_login
    unless @administrator
      ssl_authenticator_lookup
    end
    unless @administrator
      head 401
      return false
    end
    return true
  end

  def admin_login
    return false unless ssl_login
    unless @administrator.admin?
      head 403
      return false
    end
    true
  end

end
