#
# public_key is stored in BINARY (DER) format
#
class Administrator < ApplicationRecord
  before_save :default_values

  def default_values
    self.admin       ||= false
    self.enabled     ||= false
    self.prospective ||= true
  end

  def certificate
    @admin_cert ||= OpenSSL::X509::Certificate.new(public_key)
  end
  def certificate_pem
    certificate.to_pem
  end

  def self.find_by_cert(cert)
    Administrator.find_by_public_key(cert.to_der) || Administrator.find_by_public_key(cert.to_pem)
  end

  def self.create_from_certificate(cert, name)
    Administrator.create(public_key: cert.to_der,
                         name: name)
  end

  def admin!
    self.admin = true
    save!
  end

  def enable!
    self.enabled = true
    save!
  end

  def pubkey_from_file(file)
    File.open(file, "rb") { |file|
      cert = OpenSSL::X509::Certificate.new(file)
      self.public_key = cert.to_der
    }
    save
  end

end
