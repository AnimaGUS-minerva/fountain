require 'rails_helper'

RSpec.describe "Est", type: :request do

  describe "unsigned voucher request" do
    it "should get posted to requestvoucher" do

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

      post "/.well-known/est/requestvoucher", voucherrequest.merge(format: 'json')
      expect(response).to have_http_status(200)
    end
  end

  describe "signed voucher request" do
    it "should get posted to requestvoucher" do

      result = IO.read("spec/files/voucher_081196FFFE0181E0.pkcs")
      voucher_request = nil
      stub_request(:post, "https://highway.sandelman.ca/.well-known/est/requestvoucher").
        with(headers: {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/pkcs7-mime; smime-type=voucher-request', 'Host'=>'highway.sandelman.ca', 'User-Agent'=>'Ruby'}).
        to_return(status: 200, body: lambda { |request|
                    voucher_request = request.body
                    result},
                  headers: {
                    'Content-Type'=>'application/pkcs7-mime; smime-type=voucher'
                  })

      # get the Base64 of the signed request
      body = IO.read("spec/files/vr_081196FFFE0181E0.pkcs")

      clientcert = IO.binread("spec/certs/12-00-00-66-4D-02.crt")

      env = Hash.new
      env["SSL_CLIENT_CERT"] = clientcert
      env["HTTP_ACCEPT"]  = "application/pkcs7-mime; smime-type=voucher"
      env["CONTENT_TYPE"] = "application/pkcs7-mime; smime-type=voucher-request"
      post '/.well-known/est/requestvoucher', body, env

      expect(assigns(:voucherreq)).to_not be_nil
      expect(assigns(:voucherreq).tls_clientcert).to_not be_nil
      expect(assigns(:voucherreq).pledge_request).to_not be_nil
      expect(assigns(:voucherreq).signed).to be_truthy
      expect(assigns(:voucherreq).node).to_not be_nil
      expect(assigns(:voucherreq).manufacturer).to be_present

      expect(Chariwt.cmp_pkcs_file(voucher_request,
                                   "voucher_request_081196FFFE0181E0")).to be true

    end
  end


end
