class Manufacturer < ApplicationRecord
  has_many :devices
  has_many :voucher_requests
  has_many :device_types

  enum trust: {
         unknown: "unknown",     # a new manufacturer, unknown trust.
         firstused: "firstused",  # a new manufacturer, first time encountered.
         admin: "admin",         # manufacturer that was firstused, now blessed.
         brski: "brksi",         # manufacturer can be trusted if voucher obtained.
         webpki: "webpki"        # manufacturer can be trusted if MASA has valid WebPKI.
       },  _prefix: :trust

  def self.trusted_client_by_pem(clientpem)
    # decode the clientpem into a certificate
    begin
      cert = OpenSSL::X509::Certificate.new(clientpem)
    rescue OpenSSL::X509::CertificateError
      return nil
    end

    # look for a device with the same public key.
    return nil unless cert

    find_manufacturer_by(cert).first
  end

  def self.find_manufacturer_by(cert)
    return nil unless cert
    issuer = cert.issuer
    manu1  = nil
    where(:issuer_dn => issuer.to_s).each { |manu|

      manu1 = manu

      # now verify that the public key validates the certificate given.
      manukey = OpenSSL::PKey.read(manu.issuer_public_key)
      if cert.verify(manukey)
        return [manu,manu]
      end
    }
    return [nil,manu1]
  end

  def self.find_or_create_manufacturer_by(cert)
    (manu,manu1) = find_manufacturer_by(cert)
    return manu if manu

    # if we get here, no key validated the certificate,
    # but maybe we found something with the same issuer, if
    # so, go with it.
    #
    # if not, then create the something with the same issuer if
    # open registrar variable is enabled.
    #
    if SystemVariable.boolvalue?(:open_registrar)
      unless manu1
        manu1 = create(:issuer_dn => issuer.to_s)
        manu1.trust_firstused!
        manu1.name = sprintf("unknown manufacturer #%u", manu1.id)
        manu1.save!
      end
    end

    return manu1
  end
end
