class Voucher < ActiveRecord::Base
  belongs_to :manufacturer
  belongs_to :device
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

