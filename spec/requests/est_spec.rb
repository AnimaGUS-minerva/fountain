require 'rails_helper'

RSpec.describe "Est", type: :request do

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

  def clientcert
    @clientcert ||= IO.binread("spec/certs/081196FFFE0181E0.crt")
  end

  def cbor_clientcert
    @cbor_clientcert ||= IO.binread("spec/certs/010009-idevid.pem")
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

  describe "signed voucher request" do
    it "should get HTTPS POSTed to requestvoucher" do

      result = IO.read("spec/files/voucher_081196FFFE0181E0.pkcs")
      voucher_request = nil
      @time_now = Time.at(1507671037)  # Oct 10 17:30:44 EDT 2017

      allow(Time).to receive(:now).and_return(@time_now)
      stub_request(:post, "https://highway.sandelman.ca/.well-known/est/requestvoucher").
        with(headers:
               {'Accept'=>'*/*',
                'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'Content-Type'=>'application/pkcs7-mime; smime-type=voucher-request',
                'Host'=>'highway.sandelman.ca',
                'User-Agent'=>'Ruby'
               }).
        to_return(status: 200, body: lambda { |request|
                    voucher_request = request.body
                    result},
                  headers: {
                    'Content-Type'=>'application/pkcs7-mime; smime-type=voucher'
                  })

      # get the Base64 of the signed request
      body = IO.read("spec/files/vr_081196FFFE0181E0.pkcs")

      env = Hash.new
      env["SSL_CLIENT_CERT"] = clientcert
      env["HTTP_ACCEPT"]  = "application/pkcs7-mime; smime-type=voucher"
      env["CONTENT_TYPE"] = "application/pkcs7-mime; smime-type=voucher-request"
      post '/.well-known/est/requestvoucher', :params => body, :headers => env

      expect(assigns(:voucherreq)).to_not be_nil
      expect(assigns(:voucherreq).tls_clientcert).to_not be_nil
      expect(assigns(:voucherreq).pledge_request).to_not be_nil
      expect(assigns(:voucherreq).signed).to be_truthy
      expect(assigns(:voucherreq).node).to_not be_nil
      expect(assigns(:voucherreq).manufacturer).to be_present

      expect(Chariwt.cmp_pkcs_file(voucher_request,
                                   "voucher_request_081196FFFE0181E0",
                                   "spec/files/cert/certs.crt"
                                  )).to be true

    end


    it "should get CoAPS POSTed to cbor_rv" do
      result = IO.read("spec/files/voucher_00-D0-E5-01-00-09.vch")
      voucher_request = nil
      @time_now = Time.at(1507671037)  # Oct 10 17:30:44 EDT 2017
      allow(Time).to receive(:now).and_return(@time_now)

      stub_request(:post, "https://masa.wheezes.sandelman.ca/.well-known/est/requestvoucher").
        with(headers: {
               'Accept'=>'*/*',
               'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
               'Content-Type'=>'application/pkcs7-mime; smime-type=voucher-request',
               'Host'=>'masa.wheezes.sandelman.ca',
               'User-Agent'=>'Ruby'
             }).
        to_return(status: 200, body: lambda { |request|
                    voucher_request = request.body
                    result},
                  headers: {
                    'Content-Type'=>'application/pkcs7-mime; smime-type=voucher'
                  })


      # get the Base64 of the signed request
      body = IO.read("spec/files/vr_00-D0-E5-01-00-09.cwt")

      env = Hash.new
      env["SSL_CLIENT_CERT"] = cbor_clientcert
      env["HTTP_ACCEPT"]  = "application/voucher-cose+cbor"
      env["CONTENT_TYPE"] = "application/voucher-cose+cbor"
      pending "EST"
      post '/e/rv', :params => body, :headers => env

      expect(assigns(:voucherreq)).to_not be_nil
      expect(assigns(:voucherreq).tls_clientcert).to_not be_nil
      expect(assigns(:voucherreq).pledge_request).to_not be_nil
      expect(assigns(:voucherreq).signed).to be_truthy
      expect(assigns(:voucherreq).node).to_not be_nil
      expect(assigns(:voucherreq).manufacturer).to be_present

      expect(Chariwt.cmp_pkcs_file(voucher_request,
                                   "voucher_request_081196FFFE0181E0",
                                   "spec/files/cert/certs.crt"
                                  )).to be true

    end

  end


end
