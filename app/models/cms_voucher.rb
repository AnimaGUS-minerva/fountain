# this is a STI subclass of Voucher

class CmsVoucher < Voucher
  def details_from_pkcs7(extracert)
    begin
      @cvoucher = Chariwt::Voucher.from_pkcs7(signed_voucher, extracert)
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

  def self.from_voucher(voucherreq, type, value, extracert)
    voucher = create(signed_voucher: value, voucher_request: voucherreq)
    voucher.details_from_pkcs7(extracert)
    voucher
  end

  def content_type
    'application/voucher-cms+json'
  end
end

