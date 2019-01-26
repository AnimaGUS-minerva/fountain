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

      #puts "Comparing #{manu.id} #{manu.issuer_dn} to #{issuer.to_s}"
      #puts "pubkey: "+(manu.issuer_public_key.blank? ? "blank" : "available")

      next if manu.issuer_public_key.blank?

      # now verify that the public key validates the certificate given.
      begin
        manukey = OpenSSL::PKey.read(manu.issuer_public_key)
      rescue OpenSSL::PKey::PKeyError
        # parse error or blank
        nil

      else
        if cert.verify(manukey)
          return [manu,manu]
        end
      end
      #puts "did not verify cert"
    }
    return [nil,manu1]
  end

  def self.find_or_create_manufacturer_by(cert)
    (manu,manu1) = find_manufacturer_by(cert)
    return manu if manu

    # we may have found something with the same issuer_dn, but
    # we can use it only if it has no public key, as if it had
    # a public key, then it should have validated this cert.
    unless manu1.try(:issuer_public_key).try(:blank?)
      manu1 = nil
    end

    # if we get here, no key validated the certificate,
    # but maybe we found something with the same issuer, if
    # so, go with it.
    #
    #
    # if not, then create the something with the same issuer if
    # open registrar variable is enabled.
    #
    if SystemVariable.boolvalue?(:open_registrar)
      unless manu1
        manu1 = create(:issuer_dn => cert.issuer.to_s)
        manu1.trust_firstused!
        manu1.name = sprintf("unknown manufacturer #%u", manu1.id)
        manu1.save!
      end
    end

    return manu1
  end
end
