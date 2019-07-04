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

  describe "simpleenroll" do
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
