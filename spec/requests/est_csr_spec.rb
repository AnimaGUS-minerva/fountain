require 'rails_helper'
require 'support/pem_data'

RSpec.describe "Est", type: :request do
  fixtures :all

  def temporary_key
    ECDSA::Format::IntegerOctetString.decode(["20DB1328B01EBB78122CE86D5B1A3A097EC44EAC603FD5F60108EDF98EA81393"].pack("H*"))
  end

  # set up JRC keys to testing ones
  before(:each) do
    SystemVariable.setbool(:open_registrar, false)
    FountainKeys.ca.certdir = Rails.root.join('spec','files','cert')
  end

  describe "resource discovery" do
    it "should return a location for the EST service" do
      env = Hash.new
      env["SSL_CLIENT_CERT"] = clientcert
      get '/.well-known/core?rt=ace.est', :headers => env

      things = CoRE::Link.parse(response.body)
      expect(things.uri).to eq("/e")
    end
  end

  it "should return list of CAs from /cacerts" do
    get '/.well-known/est/cacerts'
    expect(response).to have_http_status(200)
    root = OpenSSL::X509::Certificate.new(response.body)
    expect(root.issuer.to_s).to include("Fountain Root CA")
    expect(response.content_type).to eq('application/pkix')
  end

  it "should return list of CAs from /crts" do
    get '/e/crts'
    expect(response).to have_http_status(200)
    root = OpenSSL::X509::Certificate.new(response.body)
    expect(root.issuer.to_s).to include("Fountain Root CA")
    expect(response.content_type).to eq('application/pkcs7-mime; smime-type=certs-only')
  end

  describe "CSR attributes" do
    it "should get a 401 if no client certificate" do
      get "/.well-known/est/csrattributes"
      expect(response).to have_http_status(401)
    end

    it "should get a 401 if client certificate not trusted" do
      env = Hash.new
      env["SSL_CLIENT_CERT"] = clientcert
      get "/.well-known/est/csrattributes", :headers => env
      expect(response).to have_http_status(401)
    end

    it "should be returned in non-constrained request" do
      env = Hash.new
      env["SSL_CLIENT_CERT"] = highwaytest_clientcert_f20001
      get "/.well-known/est/csrattributes", :headers => env
      expect(response).to have_http_status(200)
    end

    it "should be returned in constrained request" do
      env = Hash.new
      env["SSL_CLIENT_CERT"] = highwaytest_clientcert_f20001
      get "/e/att", :headers => env
      expect(response).to have_http_status(200)
    end

    it "should be return with a new certificate with a CSR with trusted connection" do
      env = Hash.new
      env["SSL_CLIENT_CERT"] = highwaytest_clientcert_f20001
      get "/.well-known/est/csrattributes", :headers => env

      # given that f20001 cert is used, it should assign device to
      # jadaf20001 device
      expect(assigns(:device)).to eq(devices(:jadaf20001))
      expect(response).to have_http_status(200)
    end

    it "should fail to be returned with acertificate with untrusted connection" do
      env = Hash.new
      env["SSL_CLIENT_CERT"] = clientcert
      get "/.well-known/est/csrattributes", :headers => env
      expect(response).to have_http_status(401)
    end
  end

  describe "simpleenroll" do
    # csr_blub03 is produced by reach from identical product files.
    it "should accept a CSR attributes file from an IDevID from a EST trusted manufacturer" do
      SystemVariable.setbool(:anima_acp, false)
      env = Hash.new
      env["SSL_CLIENT_CERT"] = wheezes_bulb03
      env["CONTENT_TYPE"]    = "application/pkcs10-base64"
      body = IO::read("spec/files/csr_bulb03.der")
      post "/.well-known/est/simpleenroll", :headers => env, :params => Base64.encode64(body)
      expect(assigns(:device)).to_not be_nil
      expect(assigns(:device).manufacturer).to_not be_nil
      expect(assigns(:device)).to be_trusted

      expect(response).to have_http_status(200)

      File.open("tmp/bulb03_cert.der", "wb") {|f| f.syswrite response.body }
      cert = OpenSSL::X509::Certificate.new(response.body)
      expect(cert).to_not be_nil
      expect(cert.subject).to_not be_nil
      dns = cert.subject.to_a
      cnt = 0
      dns.each { |item|
        case item[0]
        when "serialNumber"
          expect(item[1]).to eq("00-D0-E5-03-00-03")
          cnt += 1
        when "emailAddress"
          expect(item[1]).to eq("00-D0-E5-03-00-03")
          cnt += 1
        end
      }
      expect(cnt).to eq(1)
    end

    it "should accept a CSR attributes file from an IDevID from a BRSKI manufacturer with voucher" do
      SystemVariable.setbool(:anima_acp, true)
      env = Hash.new
      env["SSL_CLIENT_CERT"] = honeydukes_bulb1
      env["CONTENT_TYPE"]    = "application/pkcs10-base64"
      body = IO::read("spec/files/csr_bulb1.der")
      post "/.well-known/est/simpleenroll", :headers => env, :params => Base64.encode64(body)
      expect(response).to have_http_status(200)

      File.open("tmp/bulb1_cert.der", "wb") {|f| f.syswrite response.body }
      cert = OpenSSL::X509::Certificate.new(response.body)
      expect(cert).to_not be_nil
      expect(cert.subject).to_not be_nil
      dns = cert.subject.to_a
      cnt = 0
      dns.each { |item|
        case item[0]
        when "serialNumber"
          expect(item[1]).to eq("00-D0-E5-03-00-03")
          cnt += 1
        when "emailAddress"
          expect(item[1]).to eq("rfcSELF+fd739fc23c3440112233445500000000+@acp.example.com")
          cnt += 1
        end
      }
      expect(cnt).to eq(1)
    end

    it "should accept a CSR attributes file to renew from an LDevID signed by us" do
      pending "LDevID renewing"
      expect(false).to be true
    end

    it "should accept a CSR attributes file from a trusted endpoint" do
      pending "LDevID from pinned IDevID"
      expect(false).to be true
    end

    it "should reject CSR attributes file from an unknown IDevID" do
      pending "unknown IDevID"
      expect(false).to be true
    end

    it "should reject CSR attributes file from a known IDevID that has no voucher" do
      pending "known IDevID, no voucher"
      expect(false).to be true
    end
  end

end
