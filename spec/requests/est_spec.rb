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
    @env = nil
  end

  describe "signed pledge voucher request" do
    it "in PKCS7 format gets HTTPS POSTed to requestvoucher" do

      result = Base64.decode64(IO.read("spec/files/voucher_081196FFFE0181E0.pkcs"))
      voucher_request = nil
      @time_now = Time.at(1507671037)  # Oct 10 17:30:44 EDT 2017

      allow(Time).to receive(:now).and_return(@time_now)
      stub_request(:post, "https://highway-test.example.com:9443/.well-known/brski/requestvoucher").
        with(headers:
               {'Accept'=>['*/*', 'application/voucher-cms+json'],
                'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'Content-Type'=>'application/voucher-cms+json',
                'Host'=>'highway-test.example.com:9443',
                'User-Agent'=>'Ruby'
               }).
        to_return(status: 200, body: lambda { |request|
                    voucher_request = request.body
                    result},
                  headers: {
                    'Content-Type'=>'application/voucher-cms+json'
                  })

      # get the Base64 of the signed request
      body = Base64.decode64(IO.read("spec/files/vr_081196FFFE0181E0.b64"))

      env = Hash.new
      env["SSL_CLIENT_CERT"] = clientcert
      env["HTTP_ACCEPT"]  = "application/voucher-cms+json"
      env["CONTENT_TYPE"] = "application/voucher-cms+json"
      post '/.well-known/brski/requestvoucher', :params => body, :headers => env

      expect(response).to have_http_status(200)

      expect(assigns(:voucherreq)).to_not be_nil
      expect(assigns(:voucherreq).tls_clientcert).to_not be_nil
      expect(assigns(:voucherreq).pledge_request).to_not be_nil
      expect(assigns(:voucherreq).signed).to be_truthy
      dev = assigns(:voucherreq).device
      expect(dev).to_not be_nil
      expect(assigns(:voucherreq).manufacturer).to be_present
      expect(assigns(:voucherreq).device_identifier).to_not be_nil

      expect(Chariwt.cmp_pkcs_file(voucher_request,
                                   "voucher_request_081196FFFE0181E0",
                                   "spec/files/cert/certs.crt"
                                  )).to be true

      expect(dev.vouchers.count).to be >= 1
      expect(dev.voucher_requests.count).to be >= 1

    end

    def setup_cms_mock_03
      result = IO.read("spec/files/voucher-00-D0-E5-F2-00-03.vch")
      @time_now = Time.at(1507671037)  # Oct 10 17:30:44 EDT 2017

      allow(Time).to receive(:now).and_return(@time_now)

      StubIo.instance.peer_cert = highwaytest_masacert
      stub_request(:post, "https://highway-test.example.com:9443/.well-known/brski/requestvoucher").
        with(headers:
               {'Accept'=>['*/*', 'application/voucher-cms+json'],
                'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'Content-Type'=>'application/voucher-cms+json',
                'Host'=>'highway-test.example.com:9443',
                'User-Agent'=>'Ruby'
               }).
        to_return(status: 200, body: lambda { |request|
                    @voucher_request = request.body
                    result},
                  headers: {
                    'Content-Type'=>'application/voucher-cms+json'
                  })
    end

    def posted_cms_03
      # decode the Base64 of the pledge signed request
      body = Base64.decode64(IO.read("spec/files/vr-00-D0-E5-F2-00-03.b64"))

      @env ||= Hash.new
      @env["SSL_CLIENT_CERT"] ||= highwaytest_clientcert
      @env["HTTP_ACCEPT"]     ||= "application/voucher-cms+json"
      @env["CONTENT_TYPE"]    ||= "application/voucher-cms+json"
      post '/.well-known/brski/requestvoucher', :params => body, :headers => @env
    end

    it "in CMS format, with known manufacturer should get HTTPS POSTed to requestvoucher" do
      @voucher_request = nil

      setup_cms_mock_03
      posted_cms_03

      expect(response).to have_http_status(200)
      expect(assigns(:voucherreq)).to_not be_nil
      expect(assigns(:voucherreq).tls_clientcert).to_not be_nil
      expect(assigns(:voucherreq).pledge_request).to_not be_nil
      expect(assigns(:voucherreq).signed).to be_truthy
      expect(assigns(:voucherreq).device).to_not be_nil
      expect(assigns(:voucherreq).manufacturer).to be_present
      expect(assigns(:voucherreq).device_identifier).to_not be_nil

      expect(Chariwt.cmp_pkcs_file(@voucher_request,
                                   "voucher_request-00-D0-E5-F2-00-03.pkcs",
                                   "spec/files/cert/certs.crt"
                                  )).to be true

    end

    def setup_cms_mock_04
      result = IO.read("spec/files/product/00-D0-E5-03-00-03/voucher_00-D0-E5-03-00-03.pkcs")
      @time_now = Time.at(1507671037)  # Oct 10 17:30:44 EDT 2017

      allow(Time).to receive(:now).and_return(@time_now)

      StubIo.instance.peer_cert = florean03_clientcert
      stub_request(:post, "https://florean.sandelman.ca:9443/.well-known/brski/requestvoucher").
        with(headers:
               {'Accept'=>['*/*', 'application/voucher-cms+json'],
                'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'Content-Type'=>'application/voucher-cms+json',
                'Host'=>'florean.sandelman.ca:9443',
                'User-Agent'=>'Ruby'
               }).
        to_return(status: 200, body: lambda { |request|
                    @voucher_request = request.body
                    result},
                  headers: {
                    'Content-Type'=>'application/voucher-cms+json'
                  })

      # mark manufacturer as BRSKI trusted.
      manu = Manufacturer.create(masa_url: 'https://florean.sandelman.ca:9443/.well-known/brski/',
                                 issuer_dn: "/DC=ca/DC=sandelman/CN=florean.sandelman.ca",
                                 name: "Florean Maker")
      manu.trust_brski!
      manu.masa_url     # canonicalize it for good luck
      manu.save!
    end

    def posted_cms_04
      # decode the Base64 of the pledge signed request
      body = Base64.decode64(IO.read("spec/files/vr_00-D0-E5-03-00-03.b64"))

      @env ||= Hash.new
      @env["SSL_CLIENT_CERT"] ||= florean03_clientcert
      @env["HTTP_ACCEPT"]     ||= "application/voucher-cms+json"
      @env["CONTENT_TYPE"]    ||= "application/voucher-cms+json"
      post '/.well-known/brski/requestvoucher', :params => body, :headers => @env
    end

    it "post voucher-request 030003, but with the wrong client certificate, serial-number mismatch" do
      @voucher_request = nil

      setup_cms_mock_04
      @env = Hash.new
      @env["SSL_CLIENT_CERT"] = highwaytest_clientcert  # intentionally wrong client cert
      posted_cms_04

      expect(response).to have_http_status(406)
      vr=assigns(:voucherreq)
      expect(vr).to_not be_nil
      expect(vr.error_report).to_not be_nil
    end

    it "in CMS format, should get POSTed to an open registrar, get a voucher, and then enroll" do
      SystemVariable.setbool(:open_registrar, true)
      @voucher_request = nil

      setup_cms_mock_04
      posted_cms_04
      expect(response).to have_http_status(200)

      #env["SSL_CLIENT_CERT"] = highwaytest_clientcert
      @env["CONTENT_TYPE"]    = "application/pkcs10-base64"
      body = IO::read("spec/files/product/00-D0-E5-03-00-03/csr1.der")
      post "/.well-known/est/simpleenroll", :headers => @env, :params => Base64.encode64(body)

      expect(assigns(:device)).to_not be_nil
      expect(assigns(:device).manufacturer).to_not be_nil
      expect(assigns(:device).manufacturer).to be_trust_brski
      expect(assigns(:device)).to be_trusted

      expect(response).to have_http_status(200)

      File.open("tmp/bulb03_cert.der", "wb") {|f| f.syswrite response.body }
      cert = OpenSSL::X509::Certificate.new(response.body)
      expect(cert).to_not be_nil
    end


  end


end
