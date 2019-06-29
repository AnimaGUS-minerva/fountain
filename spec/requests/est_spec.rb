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

  describe "unsigned voucher request" do
    it "should get posted to requestvoucher" do

      pending "unsigned requests not yet implemented"

      voucherrequest = {
        "ietf-voucher-request:voucher" => {
          "nonce" => "62a2e7693d82fcda2624de58fb6722e5",
          "created-on" => "2017-01-01T00:00:00.000Z",
          "assertion"  => "proximity",
          "idevid-issuer" => "base64encodedvalue==",
          "serial-number" => "JADA123456789",
          "prior-signed-voucher"=> "base64encodedvalue=="
        }
      }

      post "/.well-known/est/requestvoucher", params: voucherrequest.merge(format: 'json')
      expect(response).to have_http_status(200)
    end
  end

  # points to https://highway.sandelman.ca
  def clientcert
    @clientcert ||= IO.binread("spec/files/product/081196FFFE0181E0/device.crt")
  end

  # fixture "device 12" (vizsla) in highway spec
  # points to https://highway-test.sandelman.ca:9443
  def cbor_clientcert_02
    @cbor_clientcert ||= IO.binread("spec/files/product/00-D0-E5-F2-00-02/device.crt")
  end

  # fixture "device 14"
  # points to https://highway-test.sandelman.ca:9443
  def cbor_clientcert_03
    @cbor_clientcert ||= IO.binread("spec/files/product/00-D0-E5-F2-00-03/device.crt")
  end

  # points to https://highway-test.sandelman.ca
  def cbor_highwaytest_clientcert
    @cbor_highwaytest_clientcert ||= IO.binread("spec/files/product/00-D0-E5-E0-00-0F/device.crt")
  end

  # points to https://highway-test.sandelman.ca, which is manufacturer #7
  def highwaytest_clientcert
    @highwaytest_clientcert ||= IO.binread("spec/files/product/00-D0-E5-F2-00-03/device.crt")
  end
  def highwaytest_masacert
    @highwaytest_masacert   ||= OpenSSL::X509::Certificate.new(IO.binread("spec/files/product/00-D0-E5-F2-00-03/masa.crt"))
  end

  # points to https://masa.honeydukes.sandelman.ca,
  # devices fixture :bulb1, private key can be found in the reach project
  def honeydukes_bulb1
    cert1_24
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

  describe "signed pledge voucher request" do
    it "in PKCS7 format gets HTTPS POSTed to requestvoucher" do

      result = Base64.decode64(IO.read("spec/files/voucher_081196FFFE0181E0.pkcs"))
      voucher_request = nil
      @time_now = Time.at(1507671037)  # Oct 10 17:30:44 EDT 2017

      allow(Time).to receive(:now).and_return(@time_now)
      stub_request(:post, "https://highway-test.example.com:9443/.well-known/est/requestvoucher").
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
      body = IO.read("spec/files/vr_081196FFFE0181E0.pkcs")

      env = Hash.new
      env["SSL_CLIENT_CERT"] = clientcert
      env["HTTP_ACCEPT"]  = "application/voucher-cms+json"
      env["CONTENT_TYPE"] = "application/voucher-cms+json"
      post '/.well-known/est/requestvoucher', :params => body, :headers => env

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
      stub_request(:post, "https://highway-test.example.com:9443/.well-known/est/requestvoucher").
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
      # get the Base64 of the parboiled signed request
      body = IO.read("spec/files/parboiled_vr-00-D0-E5-F2-00-03.pkcs")

      @env = Hash.new
      @env["SSL_CLIENT_CERT"] = highwaytest_clientcert
      @env["HTTP_ACCEPT"]  = "application/voucher-cms+json"
      @env["CONTENT_TYPE"] = "application/voucher-cms+json"
      post '/.well-known/est/requestvoucher', :params => body, :headers => @env
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

    it "in CMS format, should get POSTed to an open registrar, get a voucher, and then enroll" do
      SystemVariable.setbool(:open_registrar, true)
      @voucher_request = nil

      setup_cms_mock_03
      posted_cms_03
      expect(response).to have_http_status(200)

      #env["SSL_CLIENT_CERT"] = highwaytest_clientcert
      @env["CONTENT_TYPE"]    = "application/pkcs10-base64"
      body = IO::read("spec/files/csr_bulb03.der")
      post "/.well-known/est/simpleenroll", :headers => @env, :params => Base64.encode64(body)

      expect(assigns(:device)).to_not be_nil
      expect(assigns(:device).manufacturer).to_not be_nil
      expect(assigns(:device)).to be_trusted

      expect(response).to have_http_status(200)

      File.open("tmp/bulb03_cert.der", "wb") {|f| f.syswrite response.body }
      cert = OpenSSL::X509::Certificate.new(response.body)
      expect(cert).to_not be_nil
    end

    def start_coaps_posted
      @time_now = Time.at(1507671037)  # Oct 10 17:30:44 EDT 2017
      allow(Time).to receive(:now).and_return(@time_now)
    end

    # this request is created by cv3.sh in reach.
    def do_coaps_posted_03
      # get the Base64 of the incoming signed request
      body = IO.read("spec/files/vr_00-D0-E5-F2-00-03.vrq")

      env = Hash.new
      env["SSL_CLIENT_CERT"] = cbor_clientcert_03
      env["HTTP_ACCEPT"]  = "application/voucher-cose+cbor"
      env["CONTENT_TYPE"] = "application/voucher-cose+cbor"

      $FAKED_TEMPORARY_KEY = temporary_key
      post '/e/rv', :params => body, :headers => env
    end

    # this request is created by spec/files/product/00-D0-E5-F2-00-02/constrained.sh in reach.
    def do_coaps_posted_02
      # get the Base64 of the incoming signed request
      body = IO.read("spec/files/vr_00-D0-E5-F2-00-02.vrq")

      env = Hash.new
      env["SSL_CLIENT_CERT"] = cbor_clientcert_02
      env["HTTP_ACCEPT"]  = "application/voucher-cose+cbor"
      env["CONTENT_TYPE"] = "application/voucher-cose+cbor"

      $FAKED_TEMPORARY_KEY = temporary_key
      post '/e/rv', :params => body, :headers => env
    end

    def validate_coaps_posted(voucher_request)
      expect(assigns(:voucherreq)).to_not be_nil
      expect(assigns(:voucherreq).tls_clientcert).to_not be_nil
      expect(assigns(:voucherreq).pledge_request).to_not be_nil
      expect(assigns(:voucherreq).signed).to be_truthy
      expect(assigns(:voucherreq).device).to_not be_nil
      expect(assigns(:voucherreq).manufacturer).to be_present
      expect(assigns(:voucherreq).device_identifier).to_not be_nil

      # validate that the voucher_request can be validated with the key used.
      vr0 = Chariwt::Voucher.from_cbor_cose(voucher_request, FountainKeys.ca.jrc_pub_key)
      expect(vr0).to_not be_nil

      expect(Chariwt.cmp_vch_file(voucher_request,
                                  "parboiled_vr_00-D0-E5-F2-10-03")).to be true

      expect(Chariwt.cmp_vch_file(assigns(:voucher).signed_voucher,
                                  "voucher_00-D0-E5-F2-10-03")).to be true

      expect(Chariwt.cmp_vch_file(response.body,
                                  "voucher_00-D0-E5-F2-10-03")).to be true
    end

    it "should get CoAPS POSTed to cbor_rv" do
      # should not be 00-D0-E5-F2-10-03 XXX, but F2-00-03.
      resultio = File.open("spec/files/voucher_00-D0-E5-F2-10-03.mvch","rb")
      ct = resultio.gets
      ctvalue = ct[14..-3]
      ct2= resultio.gets
      result=resultio.read
      voucher_request = nil

      stub_request(:post, "https://highway-test.example.com:9443/.well-known/est/requestvoucher").
        with(headers: {
               'Accept'=>['*/*', 'multipart/mixed'],
               'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
               'Content-Type'=>'application/voucher-cose+cbor',
               'Host'=>'highway-test.example.com:9443',
             }).
        to_return(status: 200, body: lambda { |request|

                    voucher_request = request.body
                    result},
                  headers: {
                    'Content-Type'=>ctvalue
                  })

      start_coaps_posted
      do_coaps_posted_03
      # capture outgoing request for posterity
      if voucher_request
        File.open("tmp/parboiled_vr_00-D0-E5-F2-00-03.vrq", "wb") do |f|
          f.syswrite voucher_request
        end
      end

      expect(response).to have_http_status(200)
      validate_coaps_posted(voucher_request)
    end

    it "should get CoAPS POSTed to cbor_rv, but with mis-matched validation" do
      voucher_request = nil
      @time_now = Time.at(1507671037)  # Oct 10 17:30:44 EDT 2017
      allow(Time).to receive(:now).and_return(@time_now)

      # get the Base64 of the incoming signed request
      body = IO.read("spec/files/vr_00-D0-E5-E0-00-0F.vch")

      env = Hash.new
      env["SSL_CLIENT_CERT"] = highwaytest_clientcert_f20001
      env["HTTP_ACCEPT"]  = "application/voucher-cose+cbor"
      env["CONTENT_TYPE"] = "application/voucher-cose+cbor"

      $FAKED_TEMPORARY_KEY = temporary_key
      post '/e/rv', :params => body, :headers => env

      expect(response).to have_http_status(403)
    end

    # this uses the almec fixture, which on MASA has no key loaded,
    # so it causes a validation error to be returned.
    it "should get CoAPS POSTed to cbor_rv, onwards to highway-test, receive error" do
      voucher_request = nil
      @time_now = Time.at(1507671037)  # Oct 10 17:30:44 EDT 2017
      allow(Time).to receive(:now).and_return(@time_now)

      pending "highway-test:9443 not available" unless ENV['HIGHWAY_TEST']

      WebMock.allow_net_connect!

      # get the Base64 of the incoming signed request
      body = IO.read("spec/files/vr_00-D0-E5-F2-00-01.vrq")

      env = Hash.new
      env["SSL_CLIENT_CERT"] = highwaytest_clientcert_f20001
      env["HTTP_ACCEPT"]  = "application/voucher-cose+cbor"
      env["CONTENT_TYPE"] = "application/voucher-cose+cbor"

      $FAKED_TEMPORARY_KEY = temporary_key
      begin
        post '/e/rv', :params => body, :headers => env

      ensure
        # on non-live tests, the voucherreq is captured by the mock
        voucher_request = assigns(:voucherreq)

        # capture for posterity
        File.open("tmp/parboiled_vr_00-D0-E5-F2-00-01.vrq", "wb") do |f|
          f.syswrite voucher_request.registrar_request
        end
      end

      expect(response).to have_http_status(404)
    end

    it "should get CoAPS POSTed to cbor_rv, onwards live highway-test, good reply" do
      voucher_request = nil
      @time_now = Time.at(1507671037)  # Oct 10 17:30:44 EDT 2017
      allow(Time).to receive(:now).and_return(@time_now)

      pending "highway-test:9443 not available" unless ENV['HIGHWAY_TEST']

      WebMock.allow_net_connect!

      # get the Base64 of the incoming signed request
      body = IO.read("spec/files/vr_00-D0-E5-F2-00-03.vrq")

      env = Hash.new
      env["SSL_CLIENT_CERT"] = cbor_clientcert_03
      env["HTTP_ACCEPT"]  = "application/voucher-cose+cbor"
      env["CONTENT_TYPE"] = "application/voucher-cose+cbor"

      $FAKED_TEMPORARY_KEY = temporary_key
      begin
        post '/e/rv', :params => body, :headers => env

      ensure
        # on non-live tests, the voucherreq is captured by the mock
        voucher_request = assigns(:voucherreq)

        if voucher_request
          # capture for posterity
          File.open("tmp/parboiled_vr_00-D0-E5-F2-00-03.vrq", "wb") do |f|
            f.syswrite voucher_request.registrar_request
          end
        end
      end

      expect(response).to have_http_status(200)

      expect(assigns(:voucherreq)).to_not be_nil
      expect(assigns(:voucherreq).tls_clientcert).to_not be_nil
      expect(assigns(:voucherreq).pledge_request).to_not be_nil
      expect(assigns(:voucherreq).signed).to be_truthy
      expect(assigns(:voucherreq).device).to_not be_nil
      expect(assigns(:voucherreq).manufacturer).to be_present
      expect(assigns(:voucherreq).device_identifier).to_not be_nil

      # validate that the voucher_request can be validated with the key used.
      expect(voucher_request).to_not be_nil

      vr0 = Chariwt::Voucher.from_cbor_cose(voucher_request.registrar_request,
                                            FountainKeys.ca.jrc_pub_key)
      expect(vr0).to_not be_nil

      expect(Chariwt.cmp_vch_file(voucher_request.registrar_request,
                                  "parboiled_vr_00-D0-E5-F2-00-03")).to be true

      expect(cmp_vch_file_nosig(assigns(:voucher).signed_voucher,
                                  "voucher_00-D0-E5-F2-00-03")).to be true

      expect(cmp_vch_file_nosig(response.body,
                                  "voucher_00-D0-E5-F2-00-03")).to be true

    end

    it "should get CoAPS POSTed to cbor_rv, and cope with 404 error from MASA" do
      voucher_request = nil
      @time_now = Time.at(1507671037)  # Oct 10 17:30:44 EDT 2017
      allow(Time).to receive(:now).and_return(@time_now)

      # get the Base64 of the incoming signed request
      body = IO.read("spec/files/vr_00-D0-E5-F2-00-03.vrq")

      env = Hash.new
      env["SSL_CLIENT_CERT"] = cbor_clientcert_03
      env["HTTP_ACCEPT"]  = "application/voucher-cose+cbor"
      env["CONTENT_TYPE"] = "application/voucher-cose+cbor"

      stub_request(:post, "https://highway-test.example.com:9443/.well-known/est/requestvoucher").
        with(headers: {
               'Accept'=>['*/*', 'multipart/mixed'],
               'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
               'Content-Type'=>'application/voucher-cose+cbor',
               'Host'=>'highway-test.example.com:9443',
             }).
        to_return(status: 404)

      $FAKED_TEMPORARY_KEY = temporary_key
      post '/e/rv', :params => body, :headers => env

      expect(response).to have_http_status(404)

      expect(assigns(:voucherreq)).to_not be_nil
      expect(assigns(:voucherreq).status).to_not be_nil
      expect(assigns(:voucherreq).status["masa_voucher_error"]).to_not be_nil
    end

    it "should get CoAPS POSTed to cbor_rv, but resulting voucher multipart/mixed is invalid" do
      resultio = File.open("spec/files/voucher_00-D0-E5-F2-00-03-broken.mvch","rb")
      ct = resultio.gets
      ctvalue = ct[14..-3]
      ct2= resultio.gets
      result=resultio.read

      voucher_request = nil
      @time_now = Time.at(1507671037)  # Oct 10 17:30:44 EDT 2017
      allow(Time).to receive(:now).and_return(@time_now)

      # get the Base64 of the incoming signed request
      body = IO.read("spec/files/vr_00-D0-E5-F2-00-03.vrq")

      env = Hash.new
      env["SSL_CLIENT_CERT"] = cbor_clientcert_03
      env["HTTP_ACCEPT"]  = "application/voucher-cose+cbor"
      env["CONTENT_TYPE"] = "application/voucher-cose+cbor"

      stub_request(:post, "https://highway-test.example.com:9443/.well-known/est/requestvoucher").
        with(headers: {
               'Accept'=>['*/*', 'multipart/mixed'],
               'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
               'Content-Type'=>'application/voucher-cose+cbor',
               'Host'=>'highway-test.example.com:9443',
             }).
        to_return(status: 200,
                  body:   result,
                  headers: {
                    'Content-Type'=>ctvalue
                  })

      $FAKED_TEMPORARY_KEY = temporary_key
      post '/e/rv', :params => body, :headers => env

      expect(response).to have_http_status(404)

      expect(assigns(:voucherreq)).to_not be_nil
      expect(assigns(:voucherreq).status).to_not be_nil
      expect(assigns(:voucherreq).status["failed"]).to_not be_nil
    end

    # in order to ignore signatures in CBOR objects, look for "}}, h'" at the
    # end of the diag output, and nil it out, and also take care of time.
    def cmp_vch_file_nosig(token, basename)
      ofile = File.join(Chariwt.tmpdir, basename + ".vch")
      File.open(ofile, "wb") do |f|     f.write token      end

      # massage cbor2diag, could be done here in ruby!
      File::open("tmp/#{basename}.diag", "w") do |output|
        IO::popen("cbor2diag.rb #{ofile}") do |io|
          io.each_line { |line|
            line.gsub!(/6\: 1\([0-9]*\)/, "6: 1(time)")
            line.gsub!(/\}\}\, h'.*'\]\)$/, "}}, h'SIG'])")
            output.puts line
          }
        end
      end

      cmd = sprintf("diff tmp/%s.diag spec/files/%s.diag",
                    basename, basename)
      #puts cmd
      system(cmd)
    end

    it "should post an unsigned voucher" do

      result = Base64.decode64(IO.read("spec/files/voucher_00123456789A.pkcs"))
      voucher_request = nil
      @time_now = Time.at(1507671037)  # Oct 10 17:30:44 EDT 2017

      allow(Time).to receive(:now).and_return(@time_now)

      if false
        WebMock.allow_net_connect!

      else
        stub_request(:post, "https://highway-test.example.com:9443/.well-known/est/requestvoucher").
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
      end

      # get the JSON of the unsigned request
      body = IO.read("spec/files/raw_unsigned_vr-00-12-34-56-78-9A.json")

      env = Hash.new
      env["SSL_CLIENT_CERT"] = cbor_highwaytest_clientcert
      env["HTTP_ACCEPT"]  = "application/voucher-cms+json"
      env["CONTENT_TYPE"] = "application/json"
      post '/.well-known/est/requestvoucher', :params => body, :headers => env

      # capture outgoing request for posterity
      if voucher_request
        File.open("tmp/parboiled_vr_00-12-34-56-78-9A.vrq", "wb") do |f|
          f.syswrite voucher_request
        end
      end

      expect(response).to have_http_status(200)

      expect(assigns(:voucherreq)).to_not be_nil
      expect(assigns(:voucherreq).tls_clientcert).to_not be_nil
      expect(assigns(:voucherreq).pledge_request).to_not be_nil
      expect(assigns(:voucherreq).signed).to be_falsey
      expect(assigns(:voucherreq).device).to_not be_nil
      expect(assigns(:voucherreq).manufacturer).to be_present
      expect(assigns(:voucherreq).device_identifier).to_not be_nil

      expect(Chariwt.cmp_pkcs_file(voucher_request,
                                   "parboiled_vr_00123456789A")).to be true

    end
  end


end
