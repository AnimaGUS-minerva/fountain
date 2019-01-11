class EstController < ApiController

  # CACERTS return
  def cacerts
    render :plain => FountainKeys.ca.jrc_pub_key.to_pem,
           :content_type => 'application/pkcs7-mime; smime-type=certs-only'
  end

  def cbor_crts
    render :plain => FountainKeys.ca.jrc_pub_key.to_pem,
           :content_type => 'application/pkcs7-mime; smime-type=certs-only'
  end

  # POST /e/rv (CBOR, COSE)
  def cbor_rv
    begin
      # assumes *DTLS* version.
      clientcert_pem = request.env["SSL_CLIENT_CERT"]
      clientcert_pem ||= request.env["rack.peer_cert"]
      clientcert =  OpenSSL::X509::Certificate.new(clientcert_pem)
      @voucherreq = VoucherRequest.from_cose_cbor(request.body.read, clientcert)
      @voucherreq.tls_clientcert = clientcert
      @voucherreq.discover_manufacturer
      @voucherreq.populate_implicit_fields
      @voucherreq.proxy_ip = request.env["REMOTE_ADDR"]
      @voucherreq.save!

    rescue Chariwt::Voucher::RequestFailedValidation
      render :status => 403, :plain => "voucher request could not be validated with client certificate"
      return

    rescue VoucherRequest::InvalidVoucherRequest
      head 406
      return
    end

    logger.info "voucher request from #{request.env["REMOTE_ADDR"]}"

    begin
      @voucher = @voucherreq.get_voucher
    rescue VoucherRequest::BadMASA => e
      logger.info "invalid MASA response: #{e.message}"
      head 404, text: e.message
      return
    end

    if @voucher
      render :body => @voucher.signed_voucher,
             :content_type => 'application/voucher-cose+cbor',
             :charset => nil
      logger.info "returned voucher successfully"
    else
      head 500
    end

  end

  # POST /.well-known/est/requestvoucher
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
  def cbor_rv
    unless trusted_client
      head 401
    end
    head 406
  end

  # GET /.well-known/est/csrattributes
  def csrattributes
    device = trusted_client
    unless device
      head 401
    end

    #
    # allocate a prefix for this client, store it in the client structure.
    #
    prefix = SystemVariable.acp_pool_allocate
    device.acp_prefix = prefix.to_s

    head 406
  end

  private

  # examines the SSL_CLIENT_CERT (or rack.peer_cert) for a certificate
  # when found, it looks for the manufacturer by looking at the issuer.
  # if manufacturer is marked trusted, or Registrar has been marked as
  # promiscuous, then return true.
  # note that manufacturer can be marked as blacklisted instead!
  def trusted_client
    clientcert_pem = request.env["SSL_CLIENT_CERT"]
    clientcert_pem ||= request.env["rack.peer_cert"]
    unless clientcert_pem
      return false
    end

    return Manufacturer.trusted_client_by_pem(clientcert_pem)
  end

  def capture_client_info
    clientcert_pem = request.env["SSL_CLIENT_CERT"]
    clientcert_pem ||= request.env["rack.peer_cert"]
    if clientcert_pem
      @voucherreq.tls_clientcert = clientcert_pem
    end
    @voucherreq.discover_manufacturer
    @voucherreq.proxy_ip = request.env["REMOTE_ADDR"]
    @voucherreq.save!

    logger.info "voucher request from #{request.env["REMOTE_ADDR"]}"
    @voucherreq.populate_implicit_fields
  end

  def return_voucher
    begin
      @voucher = @voucherreq.get_voucher
    rescue VoucherRequest::BadMASA => e
      logger.info "invalid MASA response: #{e.message}"
      head 404, text: e.message
      return
    end

    if @voucher
      render :body => @voucher.base64_signed_voucher,
             :content_type => 'application/pkcs7-mime; smime-type=voucher'
    else
      head 500
    end
  end

  def requestvoucher_unsigned
    # would prefer to have ::Metal version, which does not parse application/json
    # until params is called.  Poorly formatted JSON may blow up, which is
    # why from_unsigned_json() does some tweaks first.
    # But, at this point something needs ApplicationController.
    @voucherreq = UnsignedVoucherRequest.from_unsigned_json(request.body.read)

    capture_client_info
    return_voucher
  end


  def requestvoucher_pkcs_signed
    token = Base64.decode64(request.body.read)
    begin
      @voucherreq = VoucherRequest.from_pkcs7_withoutkey(token)
    rescue VoucherRequest::InvalidVoucherRequest
      head 406
      return
    end

    capture_client_info
    return_voucher
  end

end
