require 'net/http'

# There are a multiciplicity of subclasses, each to deal with different cases
#
# 1) CMS signed JSON, containing (prior=CMS signed JSON)
#    This is CmsVoucherRequest subclass.
#
# 2) CMS signed CBOR, containing (prior=CMS signed CBOR)
#    This is not implemented as yet.
#
# 3) COSE signed CBOR, containing (prior=COSE signed CBOR)
#    This is CoseVoucherRequest
#
# 4) CMS signed JSON, containing unsigned JSON.
#    This is UnsignedVoucherRequest
#
# 5) CMS signed JSON, containing unsigned CBOR.
#    This is not implemented as yet.
#
# 6) CMS signed CBOR, containing unsigned CBOR.
#    This is not implemented as yet.
#

class VoucherRequest < ApplicationRecord

  belongs_to :device
  belongs_to :manufacturer
  has_many   :vouchers

  attr_accessor :certificate, :issuer_pki, :request

  class InvalidVoucherRequest < Exception; end
  class MissingPublicKey < Exception; end
  class BadMASA          < Exception; end
  class MASAHTTPFailed   < Exception; end

  def self.from_json(json, signed = false)
    vr = CmsVoucherRequest.create(details: json, signed: signed)
    vr.populate_explicit_fields
    vr
  end

  def self.from_cbor(hash: , signed: false, pubkey:)
    vr = CoseVoucherRequest.create(signed: signed)
    vr.details = hash
    vr.certificate = pubkey
    vr.populate_explicit_fields
    vr
  end

  def self.from_json_jose(token, json)
    signed = false
    vr = Chariwt::VoucherRequest.from_json_jose(token)
    if vr
      signed = true
      json = vr.vrhash
    end
    voucher = from_json(json, signed)
    voucher.request = vr
    return voucher
  end

  def self.from_cose_cbor(token, pubkey = nil)
    signed = false
    vr = Chariwt::VoucherRequest.from_cbor_cose(token, pubkey)
    if vr
      signed = true
      hash = vr.vrhash
    end
    voucher = from_cbor(hash: hash, signed: signed, pubkey: pubkey)
    voucher.request = vr
    voucher.pledge_request = token
    return voucher
  end

  def self.from_validated_json(json, signed)
  end

  def self.from_pkcs7_withkey(token, certificate)
    signed = false
    vr = Chariwt::VoucherRequest.from_pkcs7(token, certificate)
    if vr
      signed = true
      json = vr.vrhash
    end
    voucher = from_json(json, signed)
    voucher.request = vr
    voucher.pledge_request = token
    voucher.certificate = certificate
    return voucher
  end

  def self.XXfrom_pkcs7(token, json = nil)
    signed = false
    vr = Chariwt::VoucherRequest.from_pkcs7(token)
    if vr
      signed = true
      json = vr.vrhash
    end
    voucher = from_json(json, signed)
    voucher.request = vr
    voucher.pledge_request = token
    return voucher
  end

  def self.from_pkcs7_withoutkey(token, json = nil)
    signed = false
    begin
      vr = Chariwt::VoucherRequest.from_pkcs7_withoutkey(token)
    rescue Chariwt::Voucher::RequestFailedValidation
      raise VoucherRequest::InvalidVoucherRequest
    end
    if vr
      signed = true
      json = vr.vrhash
    end
    voucher = from_json(json, signed)
    voucher.request = vr
    voucher.pledge_request = token
    return voucher
  end

  # tests for what kind of voucher request, return false for all here
  # override in subclass
  def cms_voucher_request?
    false
  end
  def cose_voucher_request?
    false
  end
  def unsigned_voucher_request?
    false
  end

  def prior_voucher_request
    nil
  end

  def vdetails=(x)
    @vdetails = x
  end

  def vdetails
    unless @vdetails
      return nil unless details
      raise VoucherRequest::InvalidVoucherRequest unless details["ietf-voucher-request:voucher"]
      @vdetails = details["ietf-voucher-request:voucher"]
    end
    @vdetails
  end

  def status
    self[:status] ||= Hash.new
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
    self.device_identifier = hunt_for_serial_number
    if vdetails and vdetails["serial-number"]
      if !self.device_identifier.blank? && vdetails["serial-number"] != self.device_identifier
        logger.warn "Mismatch of serial number: IDevID: #{self.device_identifier} vs voucher-request: #{vdetails["serial-number"]}"
      end
    end
    if device_identifier
      self.device            = Device.find_or_make_by_number(device_identifier)
    end
    if self.device and self.device.try(:idevid).blank? and certificate
      self.device.idevid = certificate
    end
    self.device.save!      if self.device
    self.nonce             = vdetails["nonce"]  if vdetails
  end

  # this routine will populate additional fields that might be missing
  # by looking into the client certificate for the (D)TLS and/or key
  # that signed the voucher request
  def populate_implicit_fields
    unless device_identifier
      self.device_identifier = (subject_serialNumber || subject_cn || "").force_encoding("UTF-8")
      save!
    end
  end

  # create a voucher request (JOSE signed JSON) appropriate for sending to the MASA.
  # it shall always be signed.
  def registrar_voucher_request_json
    # now build our voucher request from the one we got.
    vreq = Chariwt::VoucherRequest.new
    vreq.signing_cert = FountainKeys.ca.jrc_pub_key
    vreq.nonce      = nonce
    vreq.serialNumber = device_identifier
    vreq.createdOn  = created_at
    vreq.assertion  = :proximity
    vreq.priorSignedVoucherRequest = pledge_request
    self.request = vreq
    jwt = vreq.jose_sign(FountainKeys.ca.jrc_priv_key)
  end

  def signing_cert
    request.try(:signing_cert)
  end

  def registrar_voucher_request
    raise InvalidVoucherRequest
  end

  def registrar_voucher_request_type
    raise InvalidVoucherRequest
  end

  def subject
    @subject ||= certificate.subject
  end
  def calc_subject_hash
    @subject_dn = Hash.new
    subject.to_a.each { |dn|
      @subject_dn[dn[0]] = dn[1]
    }
    @subject_dn
  end

  def subject_hash
    @subject_hash ||= calc_subject_hash
  end

  def subject_cn
    subject_hash["CN"]
  end
  def subject_serialNumber
    subject_hash["serialNumber"]
  end

  def certificate
    if !@certificate and !tls_clientcert.blank?
      @certificate   ||= OpenSSL::X509::Certificate.new(tls_clientcert)
    end
    @certificate   ||= signing_cert
    @certificate
  end

  def issuer_dn
    @issuer_dn   ||= certificate.issuer.to_s
  end

  def hunt_for_serial_number
    return nil unless certificate
    # BRSKI, section 2.3.1 says to look at the subject DN for the "serialNumber"
    #        it might also be in a subjectAltName HardwareModuleName, but
    #        this field might be different.
    #        This code also looks for the CN= value if no serialNumber attribute
    #        is found.
    # need some examples with HardwareModuleName
    attrs = Hash.new
    serial_number = nil
    certificate.subject.to_a.each {|attr|
      # might want to look at attr[2] for type info.
      attrs[attr[0]] = attr[1]
    }

    # look through in priority order
    return serial_number if serial_number=attrs['serialNumber']
    return serial_number if serial_number=attrs['CN']
    return nil
  end

  def discover_manufacturer
    return nil unless certificate
    manu = nil
    @masa_url = Manufacturer.extract_masa_url_from_cert(certificate)

    populate_explicit_fields

    # use MASA_URL to find a valid item.
    # note that a manufacturer might have many keys, and might also have
    # different URLs, so both need to match.
    if @masa_url
      manu1 = nil
      Manufacturer.where(masa_url: @masa_url, issuer_dn: issuer_dn).each { |manu|
        #puts "found matching manufacturer #{manu.name} by URL"
        if manu.no_key?
          manu1 = manu
          next
        end
        if manu.validates_cert?(certificate)
          unless self.device.manufacturer
            self.device.manufacturer = manu
          end
          self.manufacturer = manu
        end
      }

      unless self.device.manufacturer
        #puts "did not found a manufacturer by key"

        manu = manu1 || Manufacturer.create(masa_url: @masa_url,
                                            issuer_dn: issuer_dn)
        manu.name ||= "Manu#{manu.id}"
        manu.save!
        self.device.manufacturer = manu
        self.device.save!
      end
    end

    #puts "4 device manufacturer is '#{self.device.try(:manufacturer).id}'"
    #puts "setting voucher-request manufacturer to #{self.device.try(:manufacturer_id)}"
    if self.device
      self.manufacturer ||= self.device.manufacturer
    end
  end

  def masa_url
    discover_manufacturer
    manufacturer.try(:masa_url)
  end

  def request_voucher_uri(url = nil)
    url      ||= masa_url
    if url
      @masauri ||= URI::join(url, "requestvoucher")
    end
  end

  def security_options
    { :verify_mode => OpenSSL::SSL::VERIFY_NONE,
      :use_ssl => request_voucher_uri.scheme == 'https',
      :cert    => FountainKeys.ca.jrc_pub_key,
      :key     => FountainKeys.ca.jrc_priv_key,
    }
  end

  def http_handler
    @http_handler ||=
      Net::HTTP.start(request_voucher_uri.host, request_voucher_uri.port,
                      security_options)
  end

  def process_content_type(type, bodystr, extracert = nil)
    ct = Mail::Parsers::ContentTypeParser.parse(type)

    return [false,nil] unless ct

    parameters = ct.parameters.first

    begin
      case [ct.main_type,ct.sub_type]
      when ['application','pkcs7-mime'], ['application','cms'], ['application', 'voucher-cms+json']
        @voucher_response_type = :pkcs7

        if ct.sub_type == 'pkcs7-mime'
          @smimetype = parameters['smime-type']
          if @smimetype == 'voucher'
            @responsetype = :pkcs7_voucher
            @pkcs7voucher = true
          end
        else
          @responsetype = :pkcs7_voucher
          #@responsetype = :cms_voucher
          @pkcs7voucher = true
        end

        # it should always be binary, never any need to decode.
        # der = decode_pem(bodystr)
        der = bodystr
        voucher = ::CmsVoucher.from_voucher(self, @voucher_response_type, der, extracert)

      when ['application','voucher-cms+cbor']
        @voucher_response_type = :pkcs7
        voucher = ::CoseVoucher.from_voucher(self, @voucher_response_type, bodystr, extracert)

      when ['application','voucher-cose+cbor']
        @voucher_response_type = :cbor
        @cose = true
        voucher = ::CoseVoucher.from_voucher(self, @voucher_response_type, bodystr, extracert)

      when ['multipart','mixed']
        @voucher_response_type = :cbor
        @cose = true

        if parameters and @boundary = parameters["boundary"]
          mailbody = Mail::Body.new(bodystr)
          mailbody.split!(@boundary)
          voucher = Voucher.from_parts(self, mailbody.parts, extracert)
        else
          self.status = { :failed       => "mis-formed multipart/mixed, no boundary parameter",
                          :voucher_type => ct.to_s,
                          :parameters   => parameters,
                          :encoded_voucher => Base64::urlsafe_encode64(bodystr),
                          :masa_url     => request_voucher_uri.to_s }
          save!
          return nil
        end

      else
        self.status = { :failed       => "invalid mime type: #{type} found",
                        :voucher_type => ct.to_s,
                        :parameters   => parameters,
                        :encoded_voucher => Base64::urlsafe_encode64(bodystr),
                        :masa_url     => request_voucher_uri.to_s }
        save!
        return nil
      end

    rescue Chariwt::Voucher::MissingPublicKey => e
      self.status = { :failed       => e.message,
                      :voucher_type => ct.to_s,
                      :parameters   => parameters,
                      :encoded_voucher => Base64::urlsafe_encode64(bodystr),
                      :masa_url     => request_voucher_uri.to_s }
      save!
      return nil
    end

    return voucher
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

  def decode_pem(base64stuff)
    begin
      der = Base64.urlsafe_decode64(base64stuff)
    rescue ArgumentError
      der = Base64.decode64(base64stuff)
    end
  end

  def write_mvch(filename, response)
    File.open(filename, "wb") { |f|
      f.puts "Content-Type: multipart/mixed\r\n\r\n"
      f.write response.body
    }
  end

  def get_voucher(target_url = nil)
    target_uri = request_voucher_uri(target_url)
    raise VoucherRequest::BadMASA.new("manufacturer not found") unless target_uri

    #byebug
    logger.info "Contacting server at: #{target_uri} about #{self.device_identifier} [#{self.id}]"
    logger.info "Asking for voucher of type: #{registrar_voucher_desired_type}"

    request = Net::HTTP::Post.new(target_uri)
    request.body         = self.registrar_request = registrar_voucher_request
    request.content_type = registrar_voucher_request_type
    request.add_field("Accept", registrar_voucher_desired_type)

    begin
      response = http_handler.request request     # Net::HTTPResponse object

      logger.info "MASA at #{target_uri} says #{response.message}"

    rescue
      logger.error "Error #{$!} was raised"
      raise $!
    end

    # stop here to capture the MASA response
    #byebug
    case response
    when Net::HTTPServerError
      raise VoucherRequest::BadMASA.new("MASA server error")

    when Net::HTTPNotAcceptable
      raise VoucherRequest::BadMASA.new("MASA rejects voucher request")

    when Net::HTTPBadRequest
      raise VoucherRequest::BadMASA.new("bad request")

    when Net::HTTPNotFound
      raise VoucherRequest::MASAHTTPFailed.new("masa: #{target_uri} not found, #{response.message}")

    when Net::HTTPSuccess
      ct = response['Content-Type']
      logger.info "MASA provided voucher of type #{ct}"
      #byebug
      voucher = process_content_type(ct, response.body, http_handler.peer_cert)
      unless voucher
        raise VoucherRequest::BadMASA.new("invalid returned content-type: #{ct}")
      end
      voucher.voucher_request = self
      voucher.device       = self.device
      voucher.manufacturer = self.manufacturer
      voucher.save!
      return voucher

    when Net::HTTPRedirection
      nil

    when nil
      logger.error "An error was raised, and response was not set"
      raise VoucherRequest::BadMASA.new("unknown error in request")
    end

    return nil
  end
end

