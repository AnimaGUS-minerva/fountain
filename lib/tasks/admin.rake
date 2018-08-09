# -*- ruby -*-

namespace :fountain do

  # really only used in testing: this should be corporate CA, or Verisign, etc.
  desc "Create initial administrative account with public key pair"
  task :3_admin_cert => :environment do
    curve = FountainKeys.ca.curve

    certdir = Rails.root.join('db').join('cert')
    FileUtils.mkpath(certdir)

    admin1 = Administrator.first || Administrator.create(:name => 'First Administrator')

    # make sure admin1 bit is set.
    admin1.admin = true

    # make sure that there is a private key available.
    adminprivkey_file = certdir.join("admin_#{curve}.key")
    adminpubkey_file  = certdir.join("admin_#{curve}.crt")
    if File.exists?(adminprivkey_file)
      admin_key =  OpenSSL::PKey.read(File.open(adminprivkey_file))
    else
      admin_key = OpenSSL::PKey::EC.new(curve)
      admin_key.generate_key
      File.open(adminprivkey_file, "w") do |f| f.write admin_key.to_pem end
    end

    admin_crt  = OpenSSL::X509::Certificate.new
    # cf. RFC 5280 - to make it a "v3" certificate
    admin_crt.version = 2
    admin_crt.serial  = FountainKeys.ca.serial
    admin_crt.subject = OpenSSL::X509::Name.parse "/DC=ca/DC=sandelman/CN=administrator"

    root_ca = FountainKeys.ca.rootkey
    admin_crt.issuer = root_ca.subject
    admin_crt.public_key = admin_key
    admin_crt.not_before = Time.now

    # 2 years validity
    admin_crt.not_after = admin_crt.not_before + 2 * 365 * 24 * 60 * 60

    # Extension Factory
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = admin_crt
    ef.issuer_certificate  = root_ca
    admin_crt.add_extension(ef.create_extension("basicConstraints","CA:FALSE",true))
    admin_crt.sign(FountainKeys.ca.rootprivkey, FountainKeys.ca.digest)

    File.open(adminpubkey_file,'w') do |f|
      f.write admin_crt.to_pem
    end

    admin1.enabled = true
    admin1.admin   = true
    admin1.public_key = admin_crt.to_pem
    admin1.save!

    adminp12_file = certdir.join("admin_#{curve}.p12")
    system("openssl pkcs12 -export -password pass: -inkey #{adminprivkey_file} -in #{adminpubkey_file} -out #{adminp12_file} -nodes")

    system("ls -l #{adminpubkey_file} #{adminprivkey_file} #{adminp12_file}")

  end

end
