# this is a STI subclass of Voucher

class CmsVoucher < Voucher
  def details_from_pkcs7
    begin
      @cvoucher = Chariwt::Voucher.from_pkcs7(signed_voucher)
    rescue ArgumentError, Chariwt::Voucher::RequestFailedValidation
      # some kind of pkcs7 error?
      raise VoucherFormatError
    end

    self.nonce = @cvoucher.nonce
    self.details = @cvoucher.attributes
    self.device_identifier = @cvoucher.serialNumber
    self.expires_at        = @cvoucher.expiresOn
    self.device            = Device.find_or_make_by_number(device_identifier)
    self.manufacturer      = device.manufacturer
    save!
  end

  def self.from_voucher(type, value)
    voucher = create(signed_voucher: value)
    voucher.details_from_pkcs7
    voucher
  end
end

