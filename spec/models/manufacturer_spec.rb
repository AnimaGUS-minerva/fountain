require 'rails_helper'

RSpec.describe Manufacturer, type: :model do
  fixtures :all

  describe "relations" do
    it "should have one or more devices" do
      b1 = manufacturers(:honeydukes)
      expect(b1.devices.count).to be >= 1
    end

    it "should have one or more voucher requests" do
      b1 = manufacturers(:widget1)
      expect(b1.voucher_requests).to include(voucher_requests(:vr1))
    end

    it "should have one or more device types" do
      b1 = manufacturers(:widget1)
      expect(b1.device_types.count).to be >= 1
    end
  end

  describe "trust settings" do
    it "should have an unknown trust attribute" do
      um1 = manufacturers(:unknownManu)
      expect(um1).to be_trust_unknown
    end

    it "should have a trusted for attribute" do
      um4 = manufacturers(:brskiManu)
      expect(um4).to be_trust_brski
    end

  end

  describe "trusted signatures" do
    it "should not find a mis-matched issuer" do
      # this file was created with the identical DN as highwaytest, being:
      #    DC = ca, DC = sandelman, CN = highway-test.example.com CA
      # not possible to create an end-certificate with DC = xxx though
      file = "spec/files/CAs/malicious/certs/intermediate.cert.pem"
      m1 = Manufacturer.trusted_client_by_pem(IO.binread(file))
      expect(m1).to be_nil
    end

    it "should find a manufacturer" do
      m1 = Manufacturer.trusted_client_by_pem(highwaytest_clientcert_almec_f20001)
      expect(m1).to be_trust_brski
    end
  end

  describe "trust settings" do
    it "should have a trusted for attribute" do
      um1 = manufacturers(:unknownManu)
      expect(um1).to be_trust_unknown
    end
  end

end
