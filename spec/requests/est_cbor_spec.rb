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

  describe "signed pledge voucher request" do
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

    def validate_coaps_posted_name(voucher_request, name)
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
                                  "parboiled_vr_00-D0-E5-F2-00-#{name}")).to be true

      expect(Chariwt.cmp_vch_file(assigns(:voucher).signed_voucher,
                                  "voucher_00-D0-E5-F2-00-#{name}")).to be true

      expect(Chariwt.cmp_vch_file(response.body,
                                  "voucher_00-D0-E5-F2-00-#{name}")).to be true
    end

    it "should get 03 CoAPS POSTed to cbor_rv" do
      resultio = File.open("spec/files/voucher_00-D0-E5-F2-00-03.mvch","rb")
      ct = resultio.gets
      ctvalue = ct[14..-3]
      ct2= resultio.gets
      result=resultio.read
      voucher_request = nil

      if true
        stub_request(:post, "https://highway-test.example.com:9443/.well-known/brski/requestvoucher").
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
      else
        WebMock.allow_net_connect!
      end

      start_coaps_posted
      do_coaps_posted_03
      # capture outgoing request for posterity
      if voucher_request
        File.open("tmp/parboiled_vr_00-D0-E5-F2-00-03.vrq", "wb") do |f|
          f.syswrite voucher_request
        end
      end

      expect(response).to have_http_status(200)
      validate_coaps_posted_name(voucher_request, "03")
    end

    it "should CoAPS POST F2-00-02 to cbor_rv" do
      resultio = File.open("spec/files/voucher_00-D0-E5-F2-00-02.mvch","rb")
      ct = resultio.gets
      ctvalue = ct[14..-3]
      ct2= resultio.gets
      result=resultio.read
      voucher_request = nil

      if true
        stub_request(:post, "https://highway-test.example.com:9443/.well-known/brski/requestvoucher").
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
      else
        WebMock.allow_net_connect!
      end

      start_coaps_posted
      do_coaps_posted_02
      # capture outgoing request for posterity
      if voucher_request
        File.open("tmp/parboiled_vr_00-D0-E5-F2-00-02.vrq", "wb") do |f|
          f.syswrite voucher_request
        end
      end

      expect(response).to have_http_status(200)
      validate_coaps_posted_name(voucher_request, "02")
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

    it "should get CoAPS POSTed to cbor_rv, and cope with 404 error from MASA" do
      voucher_request = nil
      @time_now = Time.at(1507671037)  # Oct 10 17:30:44 EDT 2017
      allow(Time).to receive(:now).and_return(@time_now)

      # get the incoming signed request
      body = IO.read("spec/files/vr_00-D0-E5-F2-00-03.vrq")

      env = Hash.new
      env["SSL_CLIENT_CERT"] = cbor_clientcert_03
      env["HTTP_ACCEPT"]  = "application/voucher-cose+cbor"
      env["CONTENT_TYPE"] = "application/voucher-cose+cbor"

      stub_request(:post, "https://highway-test.example.com:9443/.well-known/brski/requestvoucher").
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

      stub_request(:post, "https://highway-test.example.com:9443/.well-known/brski/requestvoucher").
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
      end

      # get the JSON of the unsigned request
      body = IO.read("spec/files/raw_unsigned_vr-00-12-34-56-78-9A.json")

      env = Hash.new
      env["SSL_CLIENT_CERT"] = cbor_highwaytest_clientcert
      env["HTTP_ACCEPT"]  = "application/voucher-cms+json"
      env["CONTENT_TYPE"] = "application/json"
      post '/.well-known/brski/requestvoucher', :params => body, :headers => env

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
