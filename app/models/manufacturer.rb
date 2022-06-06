require 'byebug'

class Manufacturer < ApplicationRecord
  has_many :devices
  has_many :voucher_requests
  has_many :device_types

  # creates trust_brski!, and trust_brski?, etc.
  enum trust: {
         unknown: "unknown",     # a new manufacturer, unknown trust.
         firstused: "firstused", # a new manufacturer, first time encountered.
         admin: "admin",         # manufacturer that was firstused, now blessed for EST-COAPS
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

    # extract the MASA extension from the certificate.
    url = extract_masa_url_from_cert(cert)

    find_manufacturer_by(cert, url).first
  end

  # this finds a manufacturer object by the manufacturer's signing certificate.
  def self.find_by_manu_cert(cert)
    where(:issuer_public_key => cert.public_key.to_der).take
  end

  def self.extract_masa_url_from_cert(certificate)
    masa_url = nil

    if certificate
      certificate.extensions.each { |ext|
        # temporary Sandelman based PEN value
        if ext.oid == "1.3.6.1.4.1.46930.2"
          masa_url = ext.value[2..-1]
          next
        end
        # early allocation of id-pe-masa-url to BRSKI
        if ext.oid == "1.3.6.1.5.5.7.1.32"
          masa_url = ext.value[2..-1]
          next
        end
        #puts "extension OID: #{ext.to_s} found"
      }
    end
    return canonicalize_masa_url(masa_url)
  end

  def anima_acp?
    SystemVariable.boolvalue?(:anima_acp)
  end

  def no_key?
    issuer_public_key.blank?
  end

  def validates_cert?(cert)
    return false if no_key?

    debugit=(Rails.env.test? and !ENV['MANUFACTURER_DEBUG'].blank?)

    issuer = cert.issuer
    puts "Comparing #{id} #{issuer_dn} " if debugit
    puts "             to #{issuer.to_s}" if debugit
    puts "pubkey: "+(issuer_public_key.blank? ? "blank" : "available") if debugit

    #byebug
    # now verify that the public key validates the certificate given.
    begin
      manukey = OpenSSL::PKey.read_derpub(issuer_public_key)
    rescue OpenSSL::PKey::PKeyError
      # parse error or blank
      puts "Failed to parse public key from manufacturer id=\##{id}" if debugit
      return false

    else
      begin
        if cert.verify(manukey)
          return true
        end
        puts "Cert did not verify, manu id=\##{id}" if debugit
      rescue OpenSSL::X509::CertificateError
        # means that key types do not match
        puts "Cert error, keys probably do not match id=\##{id}" if debugit
        return false
      end
    end

    # do not get here, but just be sure.
    return false
  end

  # this finds a manufacturer by a client/pledge certificate.
  def self.find_manufacturer_by(cert, masaurl = nil)
    return nil unless cert
    issuer = cert.issuer
    manu1  = nil

    #byebug
    scope=Manufacturer.all
    if masaurl
      scope = scope.where(masa_url: masaurl)
    end
    scope.where(issuer_dn: issuer.to_s).each { |manu|

      # keep at least one of these.
      manu1 = manu
      #byebug
      if manu.validates_cert?(cert)
        return [manu,manu]
      end
    }
    return [nil,manu1]
  end

  def self.find_or_create_manufacturer_by(cert, masaurl = nil)
    (manu,manu1) = find_manufacturer_by(cert, masaurl)
    return manu if manu

    # we may have found something with the same issuer_dn, but
    # we can use it only if it has no public key, as if it had
    # a public key, then it should have validated this cert.
    unless manu1.try(:issuer_public_key).try(:blank?)
      manu1 = nil
    end

    # if we get here, no key validated the certificate,
    # but maybe we found something with the same issuer, if
    # so, go with it.  This is only useful is the registrar
    # is open to unknown manufacturer.
    #
    #
    # if not, then create the something with the same issuer if
    # open registrar variable is enabled.
    #
    if SystemVariable.boolvalue?(:open_registrar)
      unless manu1
        manu1 = create(issuer_dn: cert.issuer.to_s, masa_url: masaurl)
        logger.info "New Manufacturer (#{manu1.id}) stored into database for #{masaurl}"
        manu1.trust_firstused!
        manu1.name = sprintf("unknown manufacturer #%u", manu1.id)
        manu1.save!
      end
    end

    return manu1
  end

  # if a voucher validates this manufacturer, then we set the
  # manufacturer as trust_brski!
  def trust_brski_if_firstused!
    if trust_firstused?
      trust_brski!
      save!
    end
  end


  def self.canonicalize_masa_url(url)
    return nil unless url
    if !url.blank? and !url.include?("/")
      url = "https://" + url + "/.well-known/brski/"
    end
    # always have a trailing /
    unless url[-1]=='/'
      url = url + '/'
    end
    url
  end

  def masa_url
    self[:masa_url] = self.class.canonicalize_masa_url(self[:masa_url])
    save
    self[:masa_url]
  end

end
