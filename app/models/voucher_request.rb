class VoucherRequest < ApplicationRecord
  belongs_to :node
  belongs_to :manufacturer
  has_many   :vouchers

  attr_accessor :certificate, :issuer_pki, :request

  class InvalidVoucherRequest < Exception; end
  class MissingPublicKey < Exception; end

  def self.from_json(json, signed = false)
    vr = create(details: json, signed: signed)
    vr.populate_explicit_fields
    vr
  end

  def self.from_json_jose(token, json)
    signed = false
    jsonresult = Chariwt::VoucherRequest.from_json_jose(token)
    if jsonresult
      signed = true
      json = jsonresult
    end
    return from_json(json, signed)
  end

  def self.from_pkcs7(token, json)
    signed = false
    jsonresult = Chariwt::VoucherRequest.from_pkcs7(token)
    if jsonresult
      signed = true
      json = jsonresult
    end
    return from_json(json, signed)
  end

  def vdetails
    raise VoucherRequest::InvalidVoucherRequest unless details["ietf-voucher-request:voucher"]
    @vdetails ||= details["ietf-voucher-request:voucher"]
  end

  def name
    "voucherreq_#{self.id}"
  end
  def savefixturefw(fw)
    voucher.savefixturefw(fw) if voucher
    owner.savefixturefw(fw)   if owner
    save_self_tofixture(fw)
  end

  def populate_explicit_fields
    self.device_identifier = vdetails["serial-number"]
    self.node              = Node.find_or_make_by_number(device_identifier)
    self.nonce             = vdetails["nonce"]
  end

  # create a voucher request (JOSE signed JSON) appropriate for sending to the MASA.
  # it shall always be signed.
  def registrar_voucher_request_json
    # now build our voucher request from the one we got.
    vreq = Chariwt::VoucherRequest.new
    vreq.owner_cert = FountainKeys.ca.jrc_pub_key
    vreq.nonce      = nonce
    vreq.serialNumber = device_identifier
    vreq.createdOn  = created_at
    vreq.assertion  = :proximity
    self.request = vreq
    jwt = vreq.jose_sign(FountainKeys.ca.jrc_priv_key)
  end

  # create a voucher request (PKCS7 signed JSON) appropriate for sending to the MASA.
  # it shall always be signed.
  def calc_registrar_voucher_request_pkcs7
    # now build our voucher request from the one we got.
    vreq = Chariwt::VoucherRequest.new
    vreq.owner_cert = FountainKeys.ca.jrc_pub_key
    vreq.nonce      = nonce
    vreq.serialNumber = device_identifier
    vreq.createdOn  = created_at
    vreq.assertion  = :proximity
    self.request = vreq
    byebug
    token = vreq.pkcs_sign(FountainKeys.ca.jrc_priv_key)
  end

  def owner_cert
    request.try(:owner_cert)
  end

  def registrar_voucher_request_pkcs7
    @pkcs7_voucher ||= calc_registrar_voucher_request_pkcs7
  end

  def certificate
    @certificate ||= OpenSSL::X509::Certificate.new(tls_clientcert)
  end

  def issuer_pki
    @issuer_pki  ||= certificate.issuer.to_der
  end

  def discover_manufacturer
    @masaurl = nil
    certificate.extensions.each { |ext|
      if ext.oid == "1.3.6.1.4.1.46930.2"
        @masa_url = ext.value[2..-1]
      end
    }
    manu = Manufacturer.where(masa_url: @masa_url).take
    unless manu
      manu = Manufacturer.where(issuer_public_key: issuer_pki).take
    end
    unless manu
      manu = Manufacturer.create(masa_url: @masa_url,
                                 issuer_public_key: issuer_pki)
      manu.name = "Manu#{manu.id}"
      manu.save!
    end

    self.manufacturer = manu
  end

  def masa_url
    manufacturer.try(:masa_url)
  end
  def masa_uri
    @marauri ||= URI::join(masa_url, "/.well-known/est/voucherrequest")
  end
  def http_handler
    @http_handler ||= Net::HTTP.new(masa_uri.host, masa_uri.port)
  end

  def process_content_type_arguments(args)
    args.each { |param|
      param.strip!
      (thing,value) = param.split(/=/)
      case thing.downcase
      when 'smime-type'
        @smimetype = value.downcase
        process_smime_type
        @responsetype = :pkcs7_voucher
      end
    }
  end

  def process_smime_type
    case @smimetype.downcase
    when 'voucher'
      @pkcs7voucher = true
      @voucher_response_type = :pkcs7
    end
  end

  def process_content_type(value)
    things = value.split(/;/)
    majortype = things.shift
    return false unless majortype

    @apptype = majortype.downcase
    case @apptype
    when 'application/pkcs7-mime'
      @pkcs7 = true
      process_content_type_arguments(things)
      return true
    end
  end
  def response_pkcs7?
    @pkcs7
  end
  def response_voucher?
    @pkcs7voucher
  end
  def response_type
    @responsetype
  end

  def get_voucher
    request = Net::HTTP::Post.new(masa_uri)
    request.body = registrar_voucher_request_pkcs7
    request.content_type = 'application/pkcs7-mime; smime-type=voucher-request'
    response = http_handler.request request # Net::HTTPResponse object

    case response
    when Net::HTTPSuccess
      if process_content_type(@content_type = response['Content-Type'])
        voucher = Voucher.from_voucher(@voucher_response_type, response.body)
        voucher.voucher_request = self
        voucher.node = self.node
        voucher.manufacturer = self.manufacturer
        return voucher
      else
        nil
      end

    when Net::HTTPRedirection
    end

    return nil
  end

end
