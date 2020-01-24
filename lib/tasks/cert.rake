# -*- ruby -*-

namespace :fountain do

  # really only used in testing: this should be corporate CA, or Verisign, etc.
  desc "Create initial self-signed CA certificate for Registrar"
  task :s1_registrar_ca => :environment do
    curve = FountainKeys.ca.curve

    ownerprivkeyfile = FountainKeys.ca.certdir.join("ownerca_#{curve}.key")
    outfile       = FountainKeys.ca.certdir.join("ownerca_#{curve}.crt")
    dnprefix = SystemVariable.string(:dnprefix) || "/DC=ca/DC=sandelman"
    dn = sprintf("%s/CN=%s Unstrung Fountain Root CA", dnprefix, SystemVariable.string(:hostname))
    puts "issuer is now: #{dn}"
    dnobj = OpenSSL::X509::Name.parse dn

    FountainKeys.ca.sign_certificate("CA", dnobj,
                                    ownerprivkeyfile,
                                    outfile, dnobj) { |cert, ef|
      cert.add_extension(ef.create_extension("basicConstraints","CA:TRUE",true))
      cert.add_extension(ef.create_extension("keyUsage","keyCertSign, cRLSign", true))
      cert.add_extension(ef.create_extension("subjectKeyIdentifier","hash",false))
      cert.add_extension(ef.create_extension("authorityKeyIdentifier","keyid:always",false))
    }
    puts "CA Certificate writtten to: #{outfile}"
  end

  desc "Create a certificate for the Registration Authority to own devices with"
  task :s2_create_registrar => :environment do

    curve = FountainKeys.ca.client_curve

    jrcprivkeyfile= FountainKeys.ca.certdir.join("jrc_#{curve}.key")
    outfile       = FountainKeys.ca.certdir.join("jrc_#{curve}.crt")
    dnprefix = SystemVariable.string(:dnprefix) || "/DC=ca/DC=sandelman"
    unless SystemVariable.string(:hostname)
      puts "Hostname must be set before generating registrar CA"
      exit 1
    end
    dn = sprintf("%s/CN=%s", dnprefix, SystemVariable.string(:hostname).chomp)
    dnobj = OpenSSL::X509::Name.parse dn

    FountainKeys.ca.sign_certificate("Registar", nil,
                                     jrcprivkeyfile,
                                     outfile, dnobj) { |cert, ef|
      begin
        n = ef.create_extension("extendedKeyUsage","cmcRA:TRUE",true)
        cert.add_extension(n)
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
    dn = sprintf("%s/CN=%s domain authority", dnprefix, SystemVariable.string(:hostname).chomp)
    dnobj = OpenSSL::X509::Name.parse dn

    FountainKeys.ca.sign_certificate("domain authority", nil,
                                     domainprivkeyfile,
                                     outfile, dnobj) { |cert, ef|
      cert.add_extension(ef.create_extension("basicConstraints","CA:TRUE",true))
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


end
