class CoseVoucherRequest < VoucherRequest
  # create a voucher request (CBOR+COSE) appropriate for sending to the MASA.
  # it shall always be signed.
  def calc_registrar_voucher_request_cose
    # now build our voucher request from the one we got.
    vreq            = Chariwt::VoucherRequest.new(format: :cose_cbor)
    vreq.signing_cert = FountainKeys.ca.jrc_pub_key
    vreq.nonce      = nonce
    vreq.serialNumber = device_identifier
    vreq.createdOn  = created_at
    vreq.assertion  = :proximity
    vreq.priorSignedVoucherRequest = pledge_request
    self.request = vreq
    token = vreq.cose_sign(FountainKeys.ca.jrc_priv_key)
  end

  def registrar_voucher_request
    @cose_voucher ||= calc_registrar_voucher_request_cose
  end

  def registrar_voucher_request_type
    'application/cbor+cose'
  end
end