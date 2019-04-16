# this is a STI subclass of Voucher
class CoseVoucher < Voucher
  def details_from_cose(pubkey = nil)
    begin
      @cvoucher = Chariwt::Voucher.from_cbor_cose(signed_voucher, pubkey)
    rescue Chariwt::Voucher::InvalidKeyType
      # missing key to validate
      raise MissingPublicKey

    rescue ArgumentError, Chariwt::Voucher::RequestFailedValidation, Chariwt::Voucher::InvalidKeyType, CBOR::MalformedFormatError
      # some kind of pkcs7 error?
      raise VoucherFormatError.new("got error in voucher: #{$!}")
    end

    self.nonce             = @cvoucher.nonce
    self.details           = @cvoucher.attributes
    self.device_identifier = @cvoucher.serialNumber
    self.expires_at        = @cvoucher.expiresOn
    self.device            = Device.find_or_make_by_number(device_identifier)
    self.manufacturer      = device.manufacturer
    save!
  end

  def signed_voucher=(x)
    self[:signed_voucher]=Base64.urlsafe_encode64(x)
  end
  def signed_voucher
    Base64.urlsafe_decode64(self[:signed_voucher])
  end

  def self.from_voucher(voucherreq, type, value, pubkey = nil)
    voucher = create(signed_voucher: value, voucher_request: voucherreq)
    voucher.details_from_cose(pubkey)
    voucher
  end
end
