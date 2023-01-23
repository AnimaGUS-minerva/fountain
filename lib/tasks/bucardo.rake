# -*- ruby -*-

namespace :fountain do

  desc "Create a certificate for the Postgres server used for database operations, BASE=/directory, LIFETIME=5years"
  task :s6_postgres_server => :environment do
    create_auxiliary_certificate("postgres")
  end

  desc "Create a certificate for the Bucardo client used for database operations, BASE=/directory, LIFETIME=5years"
  task :s7_bucardo_client => :environment do
    create_auxiliary_certificate("bucardo", "bucardo")
  end

  def create_auxiliary_certificate(certtype, cn = nil)
    base = if ENV['BASE']
             Pathname.new(ENV['BASE'])
           else
             FountainKeys.ca.certdir.join(certtype)
           end
    FileUtils::mkdir_p(base);
    curve = FountainKeys.ca.client_curve
    privkeyfile   = base.join("#{curve}.key")
    outfile       = base.join("#{curve}.crt")
    lifetime      = nil  # accept default
    if ENV['LIFETIME']
      lifetime = ENV['LIFETIME'].to_f * (60*60*24*365)
    end
    hostname = SystemVariable.string(:hostname)
    unless SystemVariable.string(:hostname)
      puts "Hostname must be set before generating registrar CA"
      exit 1
    end
    hostname.chomp!
    email= sprintf("%s@%s", certtype, hostname)
    if cn
      dn = sprintf("CN=%s", cn)
    else
      dn = sprintf("emailAddress=%s", email)
    end
    dnobj = OpenSSL::X509::Name.parse dn

    FountainKeys.ca.sign_certificate("postgres", nil,
                                     privkeyfile,
                                     outfile, dnobj, lifetime) { |cert, ef|
      begin
        cert.add_extension(ef.create_extension("subjectAltName",
                                               sprintf("email:%s,DNS:%s", email, hostname),
                                               false))
      rescue OpenSSL::X509::ExtensionError
        puts "Can not setup cmcRA extension, as openssl not patched, continuing anyway...: #{$!}"
        exit 1
      end
    }
    puts "#{certtype} Certificate writtten to: #{outfile}"
  end

end
