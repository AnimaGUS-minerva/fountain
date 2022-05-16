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
          expect(item[1]).to eq("rfc8994+fd739fc23c3440112233445500000000+@acp.example.com")
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
