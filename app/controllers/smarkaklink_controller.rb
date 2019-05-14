class SmarkaklinkController < SecureGatewayController
  include Response

  def rvr
    media_types = HTTP::Accept::MediaTypes.parse(request.env['CONTENT_TYPE'])
    content_type=request.env['CONTENT_TYPE']

    if media_types == nil or media_types.length < 1
      head 406,
           text: "unknown voucher-request content-type: #{content_type}"
      return
    end

    media_type = media_types.first
    case
    when (media_type.mime_type == 'application/json')
      requestvoucherrequest_json

    else
      head 406, text: "unknown media-type: #{content_type}"
      return
    end
  end

  # a VOUCHER is posted for the Adolescent Router
  def voucher
    content_type=request.env['CONTENT_TYPE']
    media_types = HTTP::Accept::MediaTypes.parse(content_type)
    if media_types == nil or media_types.length < 1
      head 406,
           text: "unknown voucher content-type: #{content_type}"
      return
    end

    media_type = media_types.first

    case
    when (media_type.mime_type  == 'application/voucher-cms+json')
      smarkaklink_voucher_pkcs
      return

    else
      api_response({ "version": 1, "status": false, "reason":"invalid voucher type"}, 200)
    end
  end

  private

  def admin_cert_info
    clientcert_pem = request.env["SSL_CLIENT_CERT"]
    clientcert_pem ||= request.env["rack.peer_cert"]
    unless clientcert_pem
      return false
    end

    @cert = OpenSSL::X509::Certificate.new(clientcert_pem)
  end

  def requestvoucherrequest_json
    # the requestor might be an existing administrator,  what of it?
    @cert = admin_cert_info

    # look for SPnonce, and decrypt it.
    challenge = params["ietf:request-voucher-request"]
    unless challenge
      head 400, text: "missing request-voucher-request structure"
      return
    end

    encryptedSPnonce = challenge["voucher-challenge-nonce"]
    unless encryptedSPnonce
      head 400, text: "missing voucher-challenge-nonce"
      return
    end

    sp_nonce = nil
    @ec = OpenSSL::PKey::EC::IES.new(FountainKeys.ca.jrc_priv_key, FountainKeys.ca.client_curve)
    begin
      sp_nonce = @ec.private_decrypt(Base64.urlsafe_decode64(encryptedSPnonce))
    rescue OpenSSL::PKey::EC::IES::IESError
      logger.info "SPnonce could not be decrypted, some attacker?"
      head 403, text: "incorrect gateway selected"
    end

    unless sp_nonce
      logger.info "Nonce could not be decrypted with JRC key"
      head 403, text: "nonce not acceptable"
      return
    end

    vr = Chariwt::VoucherRequest.new
    vr.generate_nonce
    vr.assertion    = :proximity
    vr.signing_cert = FountainKeys.ca.jrc_pub_key
    vr.serialNumber = vr.eui64_from_cert
    vr.createdOn    = Time.now
    vr.proximityRegistrarCert = @cert
    vr.attributes['voucher-challenge-nonce'] = sp_nonce
    smime = vr.pkcs_sign(FountainKeys.ca.jrc_priv_key)

    render :body => Base64.strict_decode64(smime),
           :content_type => CmsVoucherRequest::CMS_VOUCHER_REQUEST_TYPE,
           :charset => nil

  end

  def smarkaklink_voucher_pkcs
    # params has the binary of the voucher in it. Process it into a voucher.

    begin
      @voucher = Chariwt::Voucher.from_pkcs7(request.body.read, FountainKeys.ca.masa_crt)
      unless @voucher.try(:pinnedDomainCert)
        api_response({ "version": 1, "status": false, "reason":"voucher did not decode"}, 200)
        return
      end

      if @voucher.pinnedDomainCert == @clientcert
        # it matches, so this is our mommy!
        if @administator
          @administrator.admin!
        end
        api_response({ "version": 1, "status": true, "reason":"ok"}, 200)
        return
      end
      api_response({ "version": 1, "status": false, "reason":"voucher did not verify client"}, 200)
    end


  end


end
