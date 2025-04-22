# -*- ruby -*-

namespace :fountain do

  # while originally only used in testing, the integral CA has become the main way to deploy
  desc "Create initial self-signed CA certificate for Registrar"
  task :s1_registrar_ca => :environment do
    curve = FountainKeys.ca.domain_curve

    ownerprivkeyfile = FountainKeys.ca.certdir.join("ownerca_#{curve}.key")
    outfile       = FountainKeys.ca.certdir.join("ownerca_#{curve}.crt")
    dnprefix = SystemVariable.string(:dnprefix) || "/DC=ca/DC=sandelman"
    hostname = SystemVariable.string(:hostname)
    unless SystemVariable.string(:hostname)
      puts "Hostname must be set before generating registrar CA"
      exit 1
    end
    hostname.chomp!
    dn = sprintf("%s/CN=%s Unstrung Fountain Root CA", dnprefix, hostname)
    puts "issuer is now: #{dn}"
    dnobj = OpenSSL::X509::Name.parse dn

    FountainKeys.ca.sign_certificate("CA", dnobj,
                                    ownerprivkeyfile,
                                    outfile, dnobj) { |cert, ef|
      cert.add_extension(ef.create_extension("keyUsage","keyCertSign, cRLSign", true))
      cert.add_extension(ef.create_extension("basicConstraints","CA:TRUE",true))
      cert.add_extension(ef.create_extension("subjectKeyIdentifier","hash",false))
      cert.add_extension(ef.create_extension("authorityKeyIdentifier","keyid:always",false))
    }
    puts "CA Certificate writtten to: #{outfile}"
  end

  desc "Create a certificate for the Registration Authority to own devices with, LIFETIME=5years"
  task :s2_create_registrar => :environment do

    curve = FountainKeys.ca.client_curve
    jrcprivkeyfile= FountainKeys.ca.certdir.join("jrc_#{curve}.key")
    outfile       = FountainKeys.ca.certdir.join("jrc_#{curve}.crt")
    lifetime      = nil  # accept default
    if ENV['LIFETIME']
      lifetime = ENV['LIFETIME'].to_f * (60*60*24*365)
    end
    dnprefix = SystemVariable.string(:dnprefix) || "/DC=ca/DC=sandelman"
    hostname = SystemVariable.string(:hostname)
    unless SystemVariable.string(:hostname)
      puts "Hostname must be set before generating registrar CA"
      exit 1
    end
    hostname.chomp!
    dn = sprintf("%s/CN=%s", dnprefix, hostname)
    dnobj = OpenSSL::X509::Name.parse dn

    FountainKeys.ca.sign_certificate("Registar", nil,
                                     jrcprivkeyfile,
                                     outfile, dnobj, lifetime) { |cert, ef|
      begin
        # must be done in a single extension
        n = ef.create_extension("extendedKeyUsage","cmcRA,clientAuth,serverAuth", true)
        cert.add_extension(n)
        n = ef.create_extension("keyUsage","digitalSignature", true)
        cert.add_extension(n)
        cert.add_extension(ef.create_extension("subjectAltName",
                                               sprintf("DNS:%s", hostname),
                                               false))
      rescue OpenSSL::X509::ExtensionError
        puts "Can not setup cmcRA extension, as openssl not patched, continuing anyway..."
      end
    }
    puts "JRC Certificate writtten to: #{outfile}"
  end

  desc "Create a keypair for the domain owner to own devices with"
  task :s4_domain_authority => :environment do

    curve = FountainKeys.ca.client_curve
    domainprivkeyfile=FountainKeys.ca.certdir.join("domain_#{curve}.key")
    outfile      =FountainKeys.ca.certdir.join("domain_#{curve}.crt")

    dnprefix = SystemVariable.string(:dnprefix) || "/DC=ca/DC=sandelman"
    hostname = SystemVariable.string(:hostname).chomp
    dn = sprintf("%s/CN=%s domain authority", dnprefix, hostname)
    dnobj = OpenSSL::X509::Name.parse dn

    FountainKeys.ca.sign_certificate("domain authority", nil,
                                     domainprivkeyfile,
                                     outfile, dnobj) { |cert, ef|
      cert.add_extension(ef.create_extension("basicConstraints","CA:TRUE",true))
      cert.add_extension(ef.create_extension("subjectAltName",
                                             sprintf("DNS:%s", hostname),
                                             false))
    }
    puts "Domain Authority certificate authority written to: #{outfile}"
  end

  # utility used with testing to fill in issuer_* in manufacturers.yml
  desc "Read a certificate from CERT= and extract the base64 of the public_key to yaml"
  task :cert2pubkey => :environment do
    file = ENV['CERT']

    puts "# Reading certificate from #{file}"
    certio = IO::read(file)
    cert   = OpenSSL::X509::Certificate.new(certio)
    pubkey = cert.public_key.to_der
    manu = Hash.new
    manu["issuer_dn"] = cert.issuer.to_s
    manu["issuer_public_key"] = pubkey
    puts manu.to_yaml(:root => "manu")
  end

  desc "Read a CSR from CSR=file and sign it as if it came in via EST, LIFETIME=5years OUTFILE=foo.crt"
  task :sign_csr => :environment do

    lifetime      = nil  # accept default
    outfile       = ENV['OUTFILE'] || "device.crt"
    if ENV['LIFETIME']
      lifetime = ENV['LIFETIME'].to_f * (60*60*24*365)
    end

    filename= ENV['CSR']
    input = File.read(filename)
    unless input
      puts "No such file #{filename}"
      exit 1
    end
    csrobj = OpenSSL::X509::Request.new(input)
    unless csrobj
      puts "Can not process #{filename} into CSR object"
      exit 2
    end
    unless ENV['MANUFACTURER'].blank?
      manu = Manufacturer.find(ENV['MANUFACTURER'])
    else
      manu = Manufacturer.default_manufacturer
    end

    dev = Device.create_device_from_csr(csrobj)
    # make sure it has an acp_address allocated
    dev.acp_address_allocate!
    dev.manufacturer = manu
    dev.create_ldevid_from_csr(csrobj)
    dev.save!

    File.open(outfile, "wb") do |f| f.write dev.ldevid end
    puts "New Certificate writtten to: #{outfile}"
  end


end
