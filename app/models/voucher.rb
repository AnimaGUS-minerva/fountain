class Voucher < ActiveRecord::Base
  belongs_to :manufacturer
  belongs_to :node
  belongs_to :voucher_request

  def self.from_voucher(type, value)
    voucher = create(signed_voucher: value)

    case type
    when 'application/pkcs7-mime; smime-type=voucher'
      voucher.details_from_pkcs7
    end
    voucher
  end

  def details_from_pkcs7
    self.details = Chariwt::Voucher.from_pkcs7(signed_voucher)

  end

end
