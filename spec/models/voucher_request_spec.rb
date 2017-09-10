require 'rails_helper'

RSpec.describe VoucherRequest, type: :model do
  fixtures :all

  describe "relationships" do
    it "should have a manufacturer" do
      vr1=voucher_requests(:vr1)
      expect(vr1.node).to         be_present
      expect(vr1.manufacturer).to be_present
    end
    it "should have a voucher (response)" do
      vr1=voucher_requests(:vr1)
      expect(vr1.vouchers).to      be_present
    end
  end

  describe "signing requests" do
    it "should create a signed voucher request" do
      vr1=voucher_requests(:vr1)
      # result is a BASE64 encoded PKCS7 object
      expect(vr1.registrar_voucher_request_json).to_not be_nil

      # save it for examination elsewhere (and use by MASA tests)
      File.open(File.join("tmp", "vr_#{vr1.device_identifier}.pkcs"), "w") do |f|
        f.puts vr1.registrar_voucher_request_pkcs7
      end

      expect(vr1.owner_cert.subject.to_s).to eq("/DC=ca/DC=sandelman/CN=localhost")
    end
  end

  describe "certificates" do
    it "should find the MASA URL from the certificate" do
      vr2 = VoucherRequest.new
      vr2.tls_clientcert = IO.binread("spec/certs/12-00-00-66-4D-02.crt")
      vr2.discover_manufacturer
      expect(vr2.manufacturer).to eq(manufacturers(:widget1))
    end
  end

  describe "vouchers" do
    it "should send a signed request to the indicated MASA" do
      vr1=voucher_requests(:vr1)

    end
  end
end
