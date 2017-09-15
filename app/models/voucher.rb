class Voucher < ActiveRecord::Base
  belongs_to :manufacturer
  belongs_to :node
  belongs_to :voucher_request

  class VoucherFormatError < Exception
  end

  def self.from_voucher(type, value)
    voucher = create(signed_voucher: value)

    case type
    when 'application/pkcs7-mime; smime-type=voucher'
      voucher.details_from_pkcs7
    end
    voucher
  end

  def details_from_pkcs7
    begin
      self.details = Chariwt::Voucher.from_pkcs7(signed_voucher)
    rescue ArgumentError
      # some kind of pkcs7 error?
      raise VoucherFormatError
    end
  end

end
