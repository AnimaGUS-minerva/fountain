class EstController < ApplicationController
  skip_before_action :verify_authenticity_token

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
      @voucherreq.proxy_ip = request.env["REMOTE_ADDR"]
      @voucherreq.save!

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

    if media_types == nil or media_types.length < 1
      head 406,
           text: "unknown voucher-request content-type: #{request.content_type}"
      return
    end

    media_type = media_types.first
    case
    when (media_type.mime_type  == 'application/pkcs7-mime' and
           media_type.parameters == { 'smime-type' => 'voucher-request'} )

      requestvoucher_pkcs_signed
    else
      head 406
      return
    end
  end

  private

  def requestvoucher_pkcs_signed
    token = Base64.decode64(request.body.read)
    begin
      @voucherreq = VoucherRequest.from_pkcs7_withoutkey(token)
    rescue VoucherRequest::InvalidVoucherRequest
      head 406
      return
    end

    clientcert_pem = request.env["SSL_CLIENT_CERT"]
    clientcert_pem ||= request.env["rack.peer_cert"]
    if clientcert_pem
      @voucherreq.tls_clientcert = clientcert_pem
    end
    @voucherreq.discover_manufacturer
    @voucherreq.proxy_ip = request.env["REMOTE_ADDR"]
    @voucherreq.save!
    logger.info "voucher request from #{request.env["REMOTE_ADDR"]}"

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

end
