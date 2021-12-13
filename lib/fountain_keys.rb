class FountainKeys
  attr_accessor :devdir, :certdir, :domain_curve, :client_curve, :algo

  class InvalidAlgoType < Exception; end

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

  def algo
    @algo         ||= SystemVariable.findwithdefault('domain_algo','ecdsa').chomp
  end

  def domain_curve
    @domain_curve ||= SystemVariable.findwithdefault('domain_curve','secp384r1').chomp
  end

  def digest
    OpenSSL::Digest::SHA384.new
  end

  def client_algo
    @client_algo  ||= SystemVariable.findwithdefault('client_algo','ecdsa').chomp
  end

  def client_curve
    @client_curve ||= SystemVariable.findwithdefault('client_curve','prime256v1').chomp
  end

  def serial
    SystemVariable.nextval(:serialnumber)
  end

  def devicedir
    @devdir  ||= Rails.root.join('db').join('devices')
  end

  # default certdir depends upon environment
  # this needs to be done here, because doing it in environment.rb does not survive reloads
  def certdir
    @certdir ||= case
                 when ENV['CERTDIR']
                   Pathname.new(ENV['CERTDIR'])

                 when (Rails.env.development? or Rails.env.test?)
                   FountainKeys.ca.certdir = Rails.root.join('spec','files','cert')

                 else
                   Rails.root.join('db').join('cert')
                 end
  end
  def certdir=(x)
    @certdir = x

    # now reset all the cached CA.
    @jrc_pub_key = nil
    @jrc_priv_key= nil
    @registarkey = nil
    @domain_pub_key = nil
    @domain_priv_key = nil
    @rootkey = nil
    @rootprivkey = nil
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

  def gen_client_pkey
    case client_algo
    when 'ecdsa'
      key = OpenSSL::PKey::EC.new(domain_curve)
      key.generate_key
      key
    when 'rsa'
      key = OpenSSL::PKey::RSA.new(client_curve.to_i)  # really, strength in bits
      key
    end
  end

  def gen_domain_pkey
    case algo
    when 'ecdsa'
      key = OpenSSL::PKey::EC.new(domain_curve)
      key.generate_key
      key
    when 'rsa'
      # really, strength in bits
      key = OpenSSL::PKey::RSA.new(domain_curve.to_i)
      key
    else
      raise InvalidAlgoType;
    end
  end

  def sign_certificate(certname, issuer, privkeyfile, pubkeyfile, dnobj, duration=(2*365*24*60*60), &efblock)
    FileUtils.mkpath(certdir)

    unless duration
      duration=(2*365*24*60*60)
    end

    if File.exists?(privkeyfile)
      puts "#{certname} using existing key at: #{privkeyfile}"
      key = OpenSSL::PKey.read(File.open(privkeyfile))
    else
      # the CA's public/private key - 3*1024 + 8
      key = gen_domain_pkey
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

  def masa_crt
    # load *our* MASA key.
    @masa_crt ||= OpenSSL::X509::Certificate.new(IO::read(certdir.join("masa.crt")))
  end

  protected
  def ca_load_priv_key
    vendorprivkey=certdir.join("ownerca_#{domain_curve}.key")
    File.open(vendorprivkey) do |f|
      OpenSSL::PKey.read(f)
    end
  end

  def ca_load_pub_key
    File.open(certdir.join("ownerca_#{domain_curve}.crt"),'r') do |f|
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
