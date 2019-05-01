class CmsVoucherRequest < VoucherRequest
  def cms_voucher_request?
    true
  end

  # create a voucher request (PKCS7 signed JSON) appropriate for
  # sending to the MASA, it shall always be signed.
  # the internal pledge_request is often signed (in which case, it is
  # base64 encoded), but it may also be unsigned, in which case it is
  # just a hash.
  def calc_registrar_voucher_request_pkcs7
    # now build our voucher request from the one we got.
    vreq = Chariwt::VoucherRequest.new
    vreq.signing_cert = FountainKeys.ca.jrc_pub_key
    vreq.nonce      = nonce
    vreq.serialNumber = device_identifier
    vreq.createdOn  = created_at
    vreq.assertion  = :proximity
    vreq.cmsSignedPriorVoucherRequest!
    vreq.priorSignedVoucherRequest = pledge_request
    self.request = vreq
    token = vreq.pkcs_sign(FountainKeys.ca.jrc_priv_key, true, [FountainKeys.ca.rootkey])
  end

  def registrar_voucher_request
    @pkcs7_voucher ||= calc_registrar_voucher_request_pkcs7
  end

  CMS_VOUCHER_REQUEST_TYPE = 'application/voucher-cms+json'.freeze
  def registrar_voucher_request_type
    CMS_VOUCHER_REQUEST_TYPE
  end

  CMS_VOUCHER_TYPE = 'application/voucher-cms+json'.freeze
  def registrar_voucher_desired_type
    CMS_VOUCHER_TYPE
  end
end
