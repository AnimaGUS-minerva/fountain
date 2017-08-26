require 'rails_helper'

RSpec.describe EstController, type: :controller do

  describe "signed voucher request" do
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

      clientcert = Base64.urlsafe_encode64(IO.binread("spec/certs/12-00-00-66-4D-02.crt"))
      @request.env["SSL_CLIENT_CERT"] = clientcert

      post :requestvoucher, voucherrequest.merge(format: 'json')

      expect(assigns(:voucherreq)).to_not be_nil
      expect(assigns(:voucherreq).tls_clientcert).to_not be_nil
      expect(assigns(:voucherreq).signed).to be_falsey
      expect(assigns(:voucherreq).node).to_not be_nil
    end
  end
end
