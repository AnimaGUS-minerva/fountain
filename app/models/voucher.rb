class Voucher < ActiveRecord::Base
  belongs_to :manufacturer
  belongs_to :node
  belongs_to :voucher_request

  class VoucherFormatError < Exception
  end
  class InvalidVoucher < Exception
  end
  class UnknownVoucherType < Exception
  end
  class MissingPublicKey < Exception
  end

  def self.from_voucher(type, value)
    case type
    when :pkcs7
      return CmsVoucher.from_voucher(type, value)
    when :cose
      return CoseVoucher.from_voucher(type, value)
    else
      raise InvalidVoucher
    end
  end

  def serial_number
    details['serial-number']
  end

  def base64_signed_voucher
    Base64.strict_encode64(signed_voucher)
  end

  def owner_cert
    @owner
  end

  def assertion
    details['assertion']
  end

  def proximity?
    'proximity' == assertion
  end

end

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
    self.node            = Node.find_or_make_by_number(device_identifier)
    self.manufacturer    = node.manufacturer
    save!
  end

  def self.from_voucher(type, value)
    voucher = create(signed_voucher: value)
    voucher.details_from_pkcs7
    voucher
  end
end

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
    self.node            = Node.find_or_make_by_number(device_identifier)
    self.manufacturer    = node.manufacturer
    save!
  end

  def self.from_voucher(type, value)
    voucher = create(signed_voucher: value)
    voucher.details_from_cose
    voucher
  end
end
