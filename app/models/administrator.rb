#
# public_key is stored in BINARY (DER) format
#
class Administrator < ApplicationRecord

  def certificate
    @admin_cert ||= OpenSSL::X509::Certificate.new(public_key)
  end
  def certificate_pem
    certificate.to_pem
  end

  def pubkey_from_file(file)
    File.open(file, "rb") { |file|
      cert = OpenSSL::X509::Certificate.new(file)
      self.public_key = cert.to_der
    }
    save
  end

end
