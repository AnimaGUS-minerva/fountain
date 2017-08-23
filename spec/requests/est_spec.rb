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
end
