class FountainKeys
  attr_accessor :devdir, :certdir, :domain_curve

  def rootkey
    @rootkey ||= ca_load_pub_key
  end
  def cacert
    rootkey
  end

  def rootprivkey
    @rootprivkey ||= ca_load_priv_key
  end
  def ca_signing_key
    rootprivkey
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

  def sign_end_certificate(certname, privkeyfile, pubkeyfile, dnstr)
    dnobj = OpenSSL::X509::Name.parse dnstr

    sign_certificate(certname, nil, privkeyfile,
                     pubkeyfile, dnobj, 2*365*60*60) { |cert,ef|
      cert.add_extension(ef.create_extension("basicConstraints","CA:FALSE",true))
    }
  end

  def sign_certificate(certname, issuer, privkeyfile, pubkeyfile, dnobj, duration=(2*365*60*60), &efblock)
    FileUtils.mkpath(certdir)

    if File.exists?(privkeyfile)
      puts "#{certname} using existing key at: #{privkeyfile}"
      key = OpenSSL::PKey.read(File.open(privkeyfile))
    else
      # the CA's public/private key - 3*1024 + 8
      key = OpenSSL::PKey::EC.new(curve)
      key.generate_key
      File.open(privkeyfile, "w", 0600) do |f| f.write key.to_pem end
    end

    ncert  = OpenSSL::X509::Certificate.new
    # cf. RFC 5280 - to make it a "v3" certificate
    ncert.version = 2
    ncert.serial  = SystemVariable.randomseq(:serialnumber)
    ncert.subject = dnobj

    # note, root CA's are "self-signed", so pass dnobj.
    issuer ||= cacert.subject

    ncert.issuer = issuer
    #ncert.public_key = root_key.public_key
    ncert.public_key = key
    ncert.not_before = Time.now

    # 2 years validity
    ncert.not_after = ncert.not_before + duration

    # Extension Factory
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = ncert
    ef.issuer_certificate  = ncert

    if efblock
      efblock.call(ncert, ef)
    end
    ncert.sign(ca_signing_key, OpenSSL::Digest::SHA256.new)

    File.open(pubkeyfile,'w') do |f|
      f.write ncert.to_pem
    end
    ncert
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
