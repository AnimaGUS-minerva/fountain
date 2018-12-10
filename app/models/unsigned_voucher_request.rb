class UnsignedVoucherRequest < VoucherRequest
  def unsigned_voucher_request?
    true
  end

  # create a voucher request (PKCS7 signed JSON) appropriate for sending
  # to the MASA.
  # it shall always be signed.
  def calc_registrar_voucher_request_unsigned
    # now build our voucher request from the one we got.
    vreq = Chariwt::VoucherRequest.new
    vreq.signing_cert = FountainKeys.ca.jrc_pub_key
    vreq.nonce      = nonce
    vreq.serialNumber = device_identifier
    vreq.createdOn  = created_at
    vreq.assertion  = :proximity
    vreq.unsignedPriorVoucherRequest!
    #byebug
    vreq.priorSignedVoucherRequest = self.details
    self.request = vreq
    token = vreq.pkcs_sign(FountainKeys.ca.jrc_priv_key)
  end

  def registrar_voucher_request
    @pkcs7_voucher ||= calc_registrar_voucher_request_unsigned
  end

  def registrar_voucher_request_type
    'application/voucher-cms+json'
  end
  def registrar_voucher_desired_type
    'application/voucher-cms+json'
  end

  def prior_voucher_request
    byebug
    @prior_voucher_request ||= Chariwt::VoucherRequest.from_json(pledge_request)
  end

  def self.from_unsigned_json(json_txt)
    json = JSON.parse(json_txt.gsub("\n",''))
    vr = UnsignedVoucherRequest.create(details: json, signed: false)
    vr.pledge_request = json_txt
    vr.populate_explicit_fields
    vr
  end


end
