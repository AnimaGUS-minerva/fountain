class VoucherRequest < ApplicationRecord
  belongs_to :node
  belongs_to :manufacturer

  attr_accessor :certificate, :issuer_pki

  class InvalidVoucherRequest < Exception; end
  class MissingPublicKey < Exception; end

  def self.from_json_jose(token, json)
    signed = false
    jsonresult = Chariwt::VoucherRequest.from_json_jose(token)
    if jsonresult
      signed = true
      json = jsonresult
    end

    vr = create(details: json, signed: signed)
    vr.populate_explicit_fields
    vr
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

  def issue_voucher
    # at a minimum, this must be before a device that belongs to us!
    return nil unless device

    # must have an owner!
    return nil unless owner

    # XXX if there is another valid voucher for this device, it must be for
    # the same owner.

    ## XXX what other kinds of validation belongs here?

    voucher = Voucher.create(owner: owner,
                             device: device,
                             nonce: nonce)
    unless nonce
      voucher.expires_on = Time.now + 14.days
    end
    voucher.jose_sign!
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

end
