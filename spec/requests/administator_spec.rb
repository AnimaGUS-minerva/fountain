require 'rails_helper'

RSpec.describe "Administrators", type: :request do
  fixtures :all

  def ssl_headers(client)
    env = Hash.new
    env["SSL_CLIENT_CERT"] = client.certificate.to_pem
    env
  end

  def new_client_certificate
    # the public/private key - 3*1024 + 8
    newadmin_key = OpenSSL::PKey::EC.new('prime256v1')
    newadmin_key.generate_key

    newadmin_cert  = OpenSSL::X509::Certificate.new
    # cf. RFC 5280 - to make it a "v3" certificate
    newadmin_cert.version = 2
    newadmin_cert.serial  = 10
    newadmin_cert.subject = OpenSSL::X509::Name.parse "CN=Secure Home Gateway"

    # "self-signed"
    newadmin_cert.issuer   = newadmin_cert.subject
    newadmin_cert.public_key = newadmin_key
    newadmin_cert.not_before = 1.day.ago

    # 2 years validity
    newadmin_cert.not_after  = Time.now + 1.year

    # Extension Factory
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = newadmin_cert
    ef.issuer_certificate  = newadmin_cert
    newadmin_cert.add_extension(ef.create_extension("basicConstraints","CA:TRUE",true))
    newadmin_cert.sign(newadmin_key, OpenSSL::Digest::SHA256.new)

    return [newadmin_key, newadmin_cert]
  end

  describe "logins" do
    it "should get authenticated with a certificate" do
      ad1 = administrators(:admin1)

      get "/administrators/#{ad1.id}.json", :headers => ssl_headers(ad1)
      expect(response).to have_http_status(200)
    end

    it "should get a 401, is called without a certificate" do
      ad1 = administrators(:admin1)

      get "/administrators/#{ad1.id}.json"
      expect(response).to have_http_status(401)
    end

    it "should get a 201 created, if called with an unknown certificate" do
      # need to create a new certificate here. If we try to take one
      # from the fixtures, then it will be found.

      (newadmin_key, newadmin_cert) = new_client_certificate
      env = Hash.new
      env["SSL_CLIENT_CERT"] = newadmin_cert

      post "/administrators.json", :headers => env
      expect(response).to have_http_status(201)
      byebug
      expect(response.location).to eq(url_for(assigns(:administrator)))
    end

  end


end
