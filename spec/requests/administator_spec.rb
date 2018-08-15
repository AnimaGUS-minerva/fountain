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
      env["SSL_CLIENT_CERT"] = newadmin_cert.to_pem

      post "/administrators.json", { :headers => env,
                                     :params => {
                                       :name => 'New Guy'
                                     }}
      expect(response).to have_http_status(201)
      byebug
      expect(response.location).to eq(url_for(assigns(:administrator)))
      expect(assigns(:administrator).public_key.to_pem).to eq(newadmin_cert.to_pem)

    end

    it "should get a 201 created, if twice with same certificate" do
      # need to create a new certificate here. If we try to take one
      # from the fixtures, then it will be found.

      (newadmin_key, newadmin_cert) = new_client_certificate
      env = Hash.new
      env["SSL_CLIENT_CERT"] = newadmin_cert.to_pem

      post "/administrators.json", { :headers => env,
                                     :params => {
                                       :name => 'New Guy'
                                     }
                                   }
      expect(response).to have_http_status(201)
      firstone = url_for(assigns(:administrator))
      expect(response.location).to eq(firstone)

      # try a second time.
      post "/administrators.json", { :headers => env,
                                     :params => {
                                       :name => 'New Guy'
                                     }
                                   }
      expect(response).to have_http_status(201)
      expect(response.location).to eq(firstone)
    end
  end

  describe "update" do
    it "should reject an attempt to update the admin bit, unless poster has one" do
      frank2 = administrators(:frank2)
      frank_admin_cert = OpenSSL::X509::Certificate.new(frank2.public_key)
      env = Hash.new
      env["SSL_CLIENT_CERT"] = frank_admin_cert.to_pem

      post url_for(frank2), { :headers => env,
                              :params => {
                                :name => 'Frank Jones',
                                :admin => true
                              }
                            }
      expect(response).to have_http_status(403)
    end

    it "should rejecting a name to be update, when updating another entry" do
      frank2 = administrators(:frank2)
      frank_admin_cert = OpenSSL::X509::Certificate.new(frank2.public_key)
      env = Hash.new
      env["SSL_CLIENT_CERT"] = frank_admin_cert.to_pem

      ad1 = administrators(:admin1)
      oldname1 = ad1.name
      oldname2 = frank2.name

      post url_for(ad1), { :headers => env,
                           :params => {
                             :name => 'Frank Jones',
                           }
                         }
      expect(response).to have_http_status(403)
      ad1.reload
      expect(ad1.name).to eq(oldname1)
      frank2.reload
      expect(frank.name).to eq(oldname2)
    end

    it "should permit a name to be updated, even when not enabled" do
      frank2 = administrators(:frank2)
      frank_admin_cert = OpenSSL::X509::Certificate.new(frank2.public_key)
      env = Hash.new
      env["SSL_CLIENT_CERT"] = frank_admin_cert.to_pem

      post url_for(frank2), { :headers => env,
                              :params => {
                                :name => 'Frank Jones',
                              }
                            }
      expect(response).to have_http_status(200)
      frank2.reload
      expect(frank2.name).to eq("Frank Jones")
    end

    it "should reject updates to other fields, when not enabled" do
      frank2 = administrators(:frank2)
      frank_admin_cert = OpenSSL::X509::Certificate.new(frank2.public_key)
      env = Hash.new
      env["SSL_CLIENT_CERT"] = frank_admin_cert.to_pem
      oldpubkey = frank2.public_key

      post url_for(frank2), { :headers => env,
                              :params => {
                                :public_key => 'Baloney',
                                :prospective => false
                              }
                            }
      expect(response).to have_http_status(403)
      frank2.reload
      expect(frank2.public_key).to eq(oldpubkey)
    end

    it "should get a 201 created, ignoring enabled and admin bit, if called with an unknown certificate" do
      # need to create a new certificate here. If we try to take one
      # from the fixtures, then it will be found.

      (newadmin_key, newadmin_cert) = new_client_certificate
      env = Hash.new
      env["SSL_CLIENT_CERT"] = newadmin_cert.to_pem

      post "/administrators.json", { :headers => env,
                                     :params => {
                                       :name => 'New Guy',
                                       :admin => true
                                     }
                                   }
      expect(response).to have_http_status(201)
      byebug
      expect(response.location).to eq(url_for(assigns(:administrator)))
      expect(assigns(:administrator).admin).to eq(false)
    end
  end

  describe "show" do
    it "should return data for self administrator, when admin false" do
      # need to create a new certificate here. If we try to take one
      # from the fixtures, then it will be found.

      frank2 = administrators(:frank2)

      get url_for(frank2, :format => 'json'), :headers => ssl_headers(frank2)
      expect(response).to have_http_status(200)
    end

    it "should return data for other administrators when admin true" do
      # need to create a new certificate here. If we try to take one
      # from the fixtures, then it will be found.

      ad1    = administrators(:admin1)
      frank2 = administrators(:frank2)

      get url_for(frank2, :format => 'json'), :headers => ssl_headers(ad1)
      expect(response).to have_http_status(200)
    end

  end



end
