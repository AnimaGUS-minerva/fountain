class FountainKeys
  attr_accessor :devdir, :certdir, :domain_curve

  def rootkey
    @rootkey ||= ca_load_pub_key
  end

  def rootprivkey
    @rootprivkey ||= ca_load_priv_key
  end

  def registrarkey
    @registarkey ||= jrc_pub_key
  end

  def registrarprivkey
    @rootprivkey ||= jrc_priv_key
  end

  def curve
    'secp384r1'
  end

  def domain_curve
    @domain_curve ||= 'secp384r1'
  end

  def digest
    OpenSSL::Digest::SHA384.new
  end

  def client_curve
    'prime256v1'
  end

  def serial
    SystemVariable.nextval(:serialnumber)
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

  def jrc_pub_key
    @jrc_pub_key  ||= load_jrc_pub_key
  end
  def jrc_priv_key
    @jrc_priv_key ||= load_jrc_priv_key
  end

  def domain_pub_key
    @domain_pub_key  ||= load_domain_pub_key
  end
  def domain_priv_key
    @domain_priv_key ||= load_domain_priv_key
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

  def load_jrc_priv_key
    jrcprivkey=certdir.join("jrc_#{client_curve}.key")
    File.open(jrcprivkey) do |f|
      OpenSSL::PKey.read(f)
    end
  end

  def load_jrc_pub_key
    File.open(certdir.join("jrc_#{client_curve}.crt"),'r') do |f|
      OpenSSL::X509::Certificate.new(f)
    end
  end

  # this seems to be a dud. MCR20190202
  def load_domain_priv_key
    domainprivkey=certdir.join("domain_#{curve}.key")
    File.open(domainprivkey) do |f|
      OpenSSL::PKey.read(f)
    end
  end

  def load_domain_pub_key
    File.open(certdir.join("domain_#{curve}.crt"),'r') do |f|
      OpenSSL::X509::Certificate.new(f)
    end
  end


end
