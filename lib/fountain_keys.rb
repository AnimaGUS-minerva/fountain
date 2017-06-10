class FountainKeys

  def rootkey
    @rootkey ||= ca_load_pub_key
  end

  def rootprivkey
    @rootprivkey ||= ca_load_priv_key
  end

  def registrarkey
    @registarkey ||= load_pub_key
  end

  def registrarprivkey
    @rootprivkey ||= load_priv_key
  end

  def curve
    'secp384r1'
  end

  def digest
    OpenSSL::Digest::SHA384.new
  end

  def client_curve
    'secp256k1'
  end

  def serial
    @serial ||= 2
    @serial += 1
    @serial
  end

  def devicedir
    @devdir  ||= Rails.root.join('db').join('devices')
  end

  def certdir
    @certdir ||= Rails.root.join('db').join('cert')
  end

  def self.ca
    @ca ||= self.new
  end

  protected
  def ca_load_priv_key
    vendorprivkey=certdir.join("ownerca_#{curve}.key")
    File.open(vendorprivkey) do |f|
      OpenSSL::PKey.read(f)
    end
  end

  def ca_load_pub_key
    File.open(certdir.join("ownerca_#{curve}.crt"),'r') do |f|
      OpenSSL::X509::Certificate.new(f)
    end
  end

  def load_priv_key
    vendorprivkey=certdir.join("vendor_#{curve}.key")
    File.open(vendorprivkey) do |f|
      OpenSSL::PKey.read(f)
    end
  end

  def load_pub_key
    File.open(certdir.join("vendor_#{curve}.crt"),'r') do |f|
      OpenSSL::X509::Certificate.new(f)
    end
  end


end
