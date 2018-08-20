# this is a STI subclass of Voucher
class CoseVoucher < Voucher
  def details_from_cose
    begin
      @cvoucher = Chariwt::Voucher.from_cose_cbor(signed_voucher)
    rescue Chariwt::Voucher::InvalidKeyType
      # missing key to validate
      raise MissingPublicKey

    rescue ArgumentError, Chariwt::Voucher::RequestFailedValidation, Chariwt::Voucher::InvalidKeyType, CBOR::MalformedFormatError
      # some kind of pkcs7 error?
      raise VoucherFormatError
    end

    self.nonce             = @cvoucher.nonce
    self.details           = @cvoucher.attributes
    self.device_identifier = @cvoucher.serialNumber
    self.expires_at        = @cvoucher.expiresOn
    self.device            = Device.find_or_make_by_number(device_identifier)
    self.manufacturer      = device.manufacturer
    save!
  end

  def self.from_voucher(type, value)
    voucher = create(signed_voucher: value)
    voucher.details_from_cose
    voucher
  end
end
