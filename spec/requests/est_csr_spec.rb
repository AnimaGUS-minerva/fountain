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

    it "should return an ACP nodeName in the attributes" do
      env = Hash.new
      env["SSL_CLIENT_CERT"] = highwaytest_clientcert_f20001
      get "/.well-known/est/csrattributes", :headers => env

      # given that f20001 cert is used, it should assign device to
      # jadaf20001 device
      expect(assigns(:device)).to eq(devices(:jadaf20001))
      expect(response).to have_http_status(200)

      asn1 = OpenSSL::ASN1.decode(response.body)
      expect(asn1.value[0].value[0].value).to eq("extReq")

      # what we find is OCTETSTRING encoded again
      os   = asn1.value[0].value[1].value[0].value[2].value
      expect(os).to_not be_nil
      san  = OpenSSL::ASN1.decode(os)
      expect(san.value[0].value[0].value).to eq(CSRAttributes.acpNodeNameOID.value)
      expect(san.value[0].value[1].value).to eq("rfc8994+fd739fc23c3440112233445500000000+@acp.example.com")
      File.open("tmp/jadaf20001.csrattr.der","wb") { |f| f.write response.body }
    end

    it "should fail to be returned with acertificate with untrusted connection" do
      env = Hash.new
      env["SSL_CLIENT_CERT"] = clientcert
      get "/.well-known/est/csrattributes", :headers => env
      expect(response).to have_http_status(401)
    end
  end

end
