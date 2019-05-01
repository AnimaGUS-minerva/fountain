# XXX should this be subclass of SecureGatewayControl
class SmarkaklinkController < ApiController

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



    vr = Chariwt::VoucherRequest.new
    vr.generate_nonce
    vr.assertion    = :proximity
    vr.signing_cert = PledgeKeys.instance.idevid_pubkey
    vr.serialNumber = vr.eui64_from_cert
    vr.createdOn    = Time.now
    vr.proximityRegistrarCert = http_handler.peer_cert
    if prior_voucher
      vr.priorSignedVoucherRequest = prior_voucher
    end
    smime = vr.pkcs_sign(PledgeKeys.instance.idevid_privkey)

  end

end
