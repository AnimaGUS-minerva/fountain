require 'rails_helper'
require 'support/pem_data'

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

  describe "trust settings" do
    it "should have a trusted for attribute" do
      um1 = manufacturers(:unknownManu)
      expect(um1).to be_trust_unknown
    end
  end

  describe "manufacturer based certificate properties" do
    it "should have a certtype field" do
      um1 = manufacturers(:brskiManu)
      expect(um1).to be_certtype_acp
    end

    it "should support certtype acp" do
      m = Manufacturer.new
      m.certtype_acp!
      expect(m).to be_certtype_acp
    end

    it "should follow System variable false, if certtype blank" do
      SystemVariable.setbool(:anima_acp, false)
      m = Manufacturer.new
      expect(m).to_not be_anima_acp
    end

    it "should follow System variable false, if certtype blank" do
      SystemVariable.setbool(:anima_acp, true)
      m = Manufacturer.new
      expect(m).to be_anima_acp
    end

    it "should follow if certtype, if certtype not blank" do
      SystemVariable.setbool(:anima_acp, false)
      m = Manufacturer.new
      m.certtype_acp!
      expect(m).to be_anima_acp
    end

    it "should support certtype iot" do
      m = Manufacturer.new
      m.certtype_iot!
      expect(m).to be_certtype_iot
    end
  end

  describe "picking a manufacturer" do
    it "should not find a mis-matched issuer" do
      # this file was created with the identical DN as highwaytest, being:
      #    DC = ca, DC = sandelman, CN = highway-test.example.com CA
      # not possible to create an end-certificate with DC = xxx though
      file = "spec/files/CAs/malicious/certs/intermediate.cert.pem"
      m1 = Manufacturer.trusted_client_by_pem(IO.binread(file))
      expect(m1).to be_nil
    end

    it "should match manufacturer by masa_url, and signature" do
      m1 = Manufacturer.trusted_client_by_pem(highwaytest_clientcert_f20001)
      expect(m1).to eq(manufacturers(:brskiManu))
      expect(m1).to be_trust_brski
    end
  end

  describe "masa url" do
    it "should canonicalize masa_url to always have https://" do
      um1 = Manufacturer.create(:masa_url => "example.com")
      expect(um1.masa_url).to eq("https://example.com/.well-known/brski/")
    end
    it "should not canonicalize masa_url if it always has https://" do
      um1 = Manufacturer.create(:masa_url => "https://example.com/.well-known/brski")
      expect(um1.masa_url).to eq("https://example.com/.well-known/brski/")
    end
  end

end
