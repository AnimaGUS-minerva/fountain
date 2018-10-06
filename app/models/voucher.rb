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

  def self.from_voucher(type, value, pubkey = nil)
    case type
    when :pkcs7
      return CmsVoucher.from_voucher(type, value)
    when :cose
      return CoseVoucher.from_voucher(type, value, pubkey)
    else
      raise InvalidVoucher
    end
  end

  def self.from_parts(parts)
    pubkey = nil
    contents = nil
    type = nil
    parts.each { |part|
      case part.mime_type.downcase
      when 'application/voucher-cose+cbor'
        type = :cose
        contents = part.body.decoded

      when 'application/pkcs7-mime'
        case part.content_type_parameters['smime-type']
        when 'certs-only'
          pubkey = part.body.decoded
        end
      end
    }

    if pubkey.blank?
      raise MissingPublicKey
    end

    if type.blank? or contents.blank?
      raise InvalidVoucher
    end

    from_voucher(type, contents, pubkey)
  end

  def self.from_multipart(type, mimecontents)
    voucher_mime = Mail.read_from_string(mimecontents)

    unless voucher_mime.mime_type == "multipart/mixed"
      raise InvalidVoucher.exception("invalid content-type: #{voucher_mime.mime_type}")
    end

    byebug
    from_parts(voucher_mime.parts)
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

