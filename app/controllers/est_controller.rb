class EstController < ApiController

  # CACERTS return
  def cacerts
    render :plain => FountainKeys.ca.cacert.to_pem,
           :content_type => 'application/pkix'
    #render :plain => FountainKeys.ca.jrc_pub_key.to_pem,
    #       :content_type => 'application/pkcs7-mime; smime-type=certs-only'
  end

  def cbor_crts
    render :plain => FountainKeys.ca.cacert.to_der,
           :content_type => 'application/pkcs7-mime; smime-type=certs-only'
  end

  # POST /e/rv (CBOR, COSE)
  def cbor_rv
    @voucherreq = nil
    begin
      # assumes *DTLS* version.
      clientcert =  decode_client_certificate
      @voucherreq = VoucherRequest.from_cose_cbor(request.body.read, clientcert)
      @voucherreq.tls_clientcert = clientcert
      @voucherreq.save!

    rescue Chariwt::Voucher::RequestFailedValidation
      render :status => 403, :plain => "voucher request could not be validated with client certificate"
      return

    rescue VoucherRequest::InvalidVoucherRequest
      logger "Voucher Request was invalid"
      render :status => 406, :plain => "voucher request had invalid format"
      return
    end

    logger.info "voucher request from #{request.env["REMOTE_ADDR"]}"

    return unless capture_client_info
    return_voucher
  end

  # POST /.well-known/brski/requestvoucher
  def requestvoucher
    media_types = HTTP::Accept::MediaTypes.parse(request.env['CONTENT_TYPE'])
    content_type=request.env['CONTENT_TYPE']

    if media_types == nil or media_types.length < 1
      head 406,
           text: "unknown voucher-request content-type: #{content_type}"
      return
    end

    media_type = media_types.first
    case
    when (media_type.mime_type  == 'application/pkcs7-mime' and
           media_type.parameters == { 'smime-type' => 'voucher-request'} )
      requestvoucher_pkcs_signed

    when (media_type.mime_type  == 'application/voucher-cms+json')
      requestvoucher_pkcs_signed

    when (media_type.mime_type == 'application/json')
      requestvoucher_unsigned

    else
      head 406, text: "unknown media-type: #{content_type}"
      return
    end
  end

  # GET /e/att (CBOR, COSE)
  def cbor_att
    unless trusted_client
      head 401
    end
    head 406
  end

  # GET /.well-known/est/csrattributes
  def csrattributes
    unless trusted_client
      head 401
      return
    end

    # now make sure that there is a device allocated for this client.
    # devices are indexed by either IDevID, or LDevID.
    # @device was set by trusted_client.

    #
    # allocate a prefix for this client, store it in the client structure.
    #
    @device.acp_address_allocate!

    render :body => @device.csr_attributes.to_der,
           :content_type => 'application/csrattrs',
           :charset => nil
  end

  # POST /e/att (CBOR, COSE), and /.well-known/est/simpleenroll
  def simpleenroll
    unless trusted_client
      head 401
      return
    end

    body = request.body.read
    if request.env["CONTENT_TYPE"] == 'application/pkcs10-base64'
      body = Base64.decode64(body)
    end

    begin
      csr   = OpenSSL::X509::Request.new(body)

      @device.create_ldevid_from_csr(csr)
      @device.save!
      ldevid = @device.ldevid_cert.to_der

      render :body => ldevid,
             :content_type => 'application/pkcs7-mime',
             :charset => nil
    end
  end

  private

  # examines the SSL_CLIENT_CERT (or rack.peer_cert) for a certificate
  # when found, it looks for the manufacturer by looking at the issuer.
  # if manufacturer is marked trusted, or Registrar has been marked as
  # promiscuous, then return true.
  # note that manufacturer can be marked as blacklisted instead!
  #
  # As a side effect, @device is setup.
  def trusted_client
    cert = decode_client_certificate
    @device = Device.find_or_make_by_certificate(cert)
    unless @device
      logger.info "client cert #{cert.issuer.to_s} => #{cert.subject.to_s}, was not trusted because an associated device was not found"
    end
    return true if @device.try(:trusted?)

    logger.info "client connected to device #{@device.try(:id)} was not considered to have become trusted"

    @administrator = Administrator.find_by_cert(cert)
    # it could also be trusted by being an administrator.
    return true if @administrator.try(:admin?)
    logger.info "client connected to device #{@administrator.try(:id)} was not considered to be an admin"

    return false
  end

  def decode_client_certificate
    clientcert_pem = request.env["SSL_CLIENT_CERT"]
    clientcert_pem ||= request.env["rack.peer_cert"]

    unless clientcert_pem.instance_of? OpenSSL::X509::Certificate
      OpenSSL::X509::Certificate.new(clientcert_pem)
    else
      clientcert_pem
    end
  end

  def capture_client_certificate
    cert = decode_client_certificate
    if cert
      @voucherreq.tls_clientcert = cert.to_pem
    end
    @voucherreq.proxy_ip = request.env["REMOTE_ADDR"]
  end

  def capture_client_info
    capture_client_certificate
    @voucherreq.discover_manufacturer

    logger.info "voucher request from #{request.env["REMOTE_ADDR"]}"
    @voucherreq.populate_implicit_fields
    @voucherreq.save!

    # some validation checks on the voucher request.

    unless @voucherreq.consistency_checks
      logger.info "voucher request at \##{@voucherreq.id} had inconsistencies: #{@voucherreq.error_report}"
      head 406, text: @voucherreq.error_report
      return false
    end

    return true
  end

  def return_voucher

    begin
      @voucher = @voucherreq.get_voucher
    rescue VoucherRequest::BadMASA => e
      # this is raised when the MASA can not be reached
      @voucherreq.status["masa"] = "invalid MASA: "+e.message
      @voucherreq.save!
      logger.info "invalid MASA response: #{e.message}"
      head 404, text: e.message
      return

    rescue Voucher::VoucherFormatError => e
      # this is raised when the returned voucher is not parsable
      @voucherreq.status["masa_voucher_error"]=e.message
      @voucherreq.save!
      logger.info "invalid MASA voucher: #{e.message}, logged voucher_request id\##{@voucherreq.id}"
      head 404, text: e.message
      return

    rescue VoucherRequest::MASAHTTPFailed => e
      # this is raised when the MASA returns a 404
      @voucherreq.status["masa_voucher_error"]=e.message
      @voucherreq.save!
      logger.info "MASA does not like voucher request: #{e.message}, not voucher returned"
      head 404, text: e.message
      return
    end

    #byebug

    if @voucher
      render :body => @voucher.signed_voucher,
             :content_type => @voucher.content_type,
             :charset => nil

      logger.info "device \##{@voucher.device.id} (name: #{@voucher.device.name}) has been adopted"
      logger.info "returning voucher \##{@voucher.id} of size #{@voucher.signed_voucher.length} with ct=#{@voucher.content_type}"
      @voucher.manufacturer.trust_brski_if_firstused!
      @voucher.save!
    else
      head 500
    end
  end

  def requestvoucher_pkcs_signed
    token = request.body.read
    begin
      @voucherreq = VoucherRequest.from_pkcs7_withoutkey(token)
    rescue VoucherRequest::InvalidVoucherRequest
      @voucherreq = VoucherRequest.create(:pledge_request => token,
                                 :proxy_ip => request.env["REMOTE_ADDR"])
      capture_client_certificate
      @voucherreq.save!
      logger.info "Voucher request was not parsed, details in #{@voucherreq.id}, #{$!}"
      head 406
      return
    end

    return unless capture_client_info
    return_voucher
  end

end
