class Voucher < ActiveRecord::Base
  belongs_to :manufacturer
  belongs_to :device
  belongs_to :voucher_request
  before_save :encode_details

  class VoucherFormatError < Exception
  end
  class InvalidVoucher < Exception
  end
  class UnknownVoucherType < Exception
  end
  class MissingPublicKey < Exception
  end

  def self.from_voucher(voucherreq, type, value, pubkey = nil)
    case type
    when :pkcs7
      return CmsVoucher.from_voucher(voucherreq, type, value, pubkey)
    when :cose
      return CoseVoucher.from_voucher(voucherreq, type, value, pubkey)
    else
      raise InvalidVoucher
    end
  end

  def self.from_parts(voucherreq, parts, extracert = nil)
    pubkey = nil
    contents = nil
    type = nil
    parts.each { |part|
      case part.mime_type.downcase
      when 'application/voucher-cose+cbor'
        type = :cose
        contents = part.body.decoded

      when 'application/voucher-cms+json'
        pubkey = part.body.decoded

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

    from_voucher(voucherreq, type, contents, pubkey)
  end

  def self.from_multipart(voucherreq, type, mimecontents)
    voucher_mime = Mail.read_from_string(mimecontents)

    unless voucher_mime.mime_type == "multipart/mixed"
      raise InvalidVoucher.exception("invalid content-type: #{voucher_mime.mime_type}")
    end

    from_parts(voucherreq, voucher_mime.parts)
  end

  def encode_details
    self.encoded_details = details.to_cbor
  end

  def decode_details
    thing = nil
    unless encoded_details.blank?
      unpacker = CBOR::Unpacker.new(StringIO.new(self.encoded_details))
      unpacker.each { |things|
        thing = things
      }
    end
    thing
  end

  def details
    @details ||= decode_details || Hash.new
  end
  def details=(x)
    @details = x
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

