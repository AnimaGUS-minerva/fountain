class Manufacturer < ApplicationRecord
  has_many :devices
  has_many :voucher_requests
  has_many :device_types

  enum trust: {
         unknown: "unknown",     # a new manufacturer, unknown trust.
         firstused: "firstuse",  # a new manufacturer, first time encountered.
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

    return nil unless cert

    issuer = cert.issuer
    where(:issuer_dn => issuer.to_s).each { |manu|
      # now verify that the public key validates the certificate given.
      manukey = OpenSSL::PKey.read(manu.issuer_public_key)
      if cert.verify(manukey)
        return manu
      end
    }

    # if we get here, no key validated the certificate, return nil
    return nil
  end
end
