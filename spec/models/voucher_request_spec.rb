require 'rails_helper'

RSpec.describe VoucherRequest, type: :model do
  fixtures :all

  describe "relationships" do
    it "should have a manufacturer" do
      vr1=voucher_requests(:vr1)
      expect(vr1.node).to         be_present
      expect(vr1.manufacturer).to be_present
    end
  end

  describe "certificates" do
    it "should find the MASA URL from the certificate" do
      vr2 = VoucherRequest.new
      vr2.tls_clientcert = Base64.urlsafe_encode64(IO.binread("spec/certs/12-00-00-66-4D-02.crt"))
      vr2.discover_manufacturer
      expect(vr2.manufacturer).to eq(manufacturers(:widget1))
    end
  end
end
