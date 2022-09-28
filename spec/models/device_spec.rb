require 'rails_helper'

require 'support/mud_toaster'
require 'support/pem_data'

RSpec.describe Device, type: :model do
  fixtures :all

  before(:all) do
    FileUtils.mkdir_p("tmp")
    FountainKeys.ca.certdir = Rails.root.join('spec','files','cert')
    #FountainKeys.ca.domain_curve = "prime256v1"
  end

  before(:each) do
    Dir.glob("tmp/mudfiles/*.json") do |f| File.delete(f) end
    Dir.glob("tmp/*.tout") do |f| File.delete(f) end
    @mms = MockMudSocket.new("spec/files/mud/toaster_load.tin",
                             "tmp/toaster_load.tout")
  end

  describe "relations" do
    it "should have a manufacturer" do
      b1 = devices(:bulb1)
      expect(b1.manufacturer).to be_truthy
    end

    it "should have a device type" do
      b1 = devices(:bulb1)
      expect(b1.device_type).to be_truthy
    end

    it "should have many vouchers" do
      b1 = devices(:bulb1)
      expect(b1.vouchers.length).to be > 0
    end

    it "should have many voucher requests" do
      b1 = devices(:bulb1)
      expect(b1.voucher_requests.length).to be > 0
    end
  end

  describe "traffic counts" do
    it "should permit incrementing traffic counts" do
      t1 = devices(:thing1)
      t1.increment_bytes(:incoming, 10)
      expect(t1.traffic_counts["bytes"][0]).to eq(1244)
    end

    it "should init an empty device with zero counts" do
      t1 = Device.create
      t1.save
      expect(t1.traffic_counts["bytes"][0]).to   eq(0)
      expect(t1.traffic_counts["bytes"][1]).to   eq(0)
      expect(t1.traffic_counts["packets"][0]).to eq(0)
      expect(t1.traffic_counts["packets"][1]).to eq(0)
    end

  end

  describe "mud files" do
    it "export a mud file to disk with a reachable name" do
      toaster = devices(:toaster1)

      (file,pubname) = toaster.mud_tmp_file_name
      expect(file).to be_kind_of IO
      expect(pubname).to eq(File.join($MUD_TMPDIR_PUBLIC, "00005.json"))
    end

    it "should get written during activation of a device" do
      mwave = devices(:microwave1)

      toaster_mud
      mwave.do_activation!
      expect(File.exists?("tmp/mudfiles/00006.json")).to be true
    end

    it "should setup of a new device_type given a new mud_url" do
      mu = toaster_mud
      toaster = devices(:toaster1)
      expect(toaster.device_type).to     be_nil

      toaster.mud_url = mu
      toaster.reload
      expect(toaster.device_type).to_not be_nil
    end

    it "should communicate a new mud entry to the mud-super" do
      toaster = devices(:toaster1)
      toaster.mud_url = toaster_mud

      toaster.reload
      expect(toaster.device_type).to_not be_nil
      expect(toaster.firewall_rule_names).to_not be_nil
      expect(toaster).to be_activated
    end

    it "should update the mud-super when the mud_url changes" do
      toaster = devices(:toaster1)
      toaster.mud_url = mwave_mud

      toaster.reload
      expect(toaster.device_type).to_not be_nil
      expect(toaster.firewall_rule_names).to_not be_nil
      expect(toaster).to be_activated
    end

    it "should save mud-filter names to device_type" do
      toaster = devices(:toaster1)
      toaster.mud_url = toaster_mud
    end
  end

  describe "finding" do
    it "should lookup by hash of public key" do
      d = Device.find_by_certificate(cert1_24)
      expect(d).to_not be_nil
      expect(d).to eq(devices(:bulb1))
    end

    it "should find a new device from honeydukes" do
      d = Device.find_or_make_by_certificate(cert2_1B)
      expect(d).to_not be_nil
      expect(d.manufacturer).to_not be_nil
      expect(d.manufacturer.issuer_dn).to eq(cert2_1B.issuer.to_s)
    end

    it "should find a new device from borgin, creating a new manufacturer, if promisc registrar" do
      SystemVariable.setbool(:open_registrar, true)
      d = Device.find_or_make_by_certificate(borgin01)
      expect(d).to_not be_nil
      expect(d.manufacturer).to_not be_nil
      expect(d.manufacturer.issuer_dn).to eq(borgin01.issuer.to_s)
      expect(d.manufacturer).to           be_trust_firstused
    end

    it "should reject a new device from wheezes, not create a manufacturer, if restrictive registrar" do
      SystemVariable.setbool(:open_registrar, false)
      d = Device.find_or_make_by_certificate(borgin01)
      expect(d).to_not be_nil
      expect(d.manufacturer).to           be_nil
    end
  end

  describe "trusting" do
    it "occurs when a device has a trusted manufacturer" do
      d2 = devices(:jadaf20001)
      expect(d2.trusted?).to be true
    end

    it "occurs when device has an LDevID signed by us" do
      pending "no ldevid examples yet"
      d2 = devices(:n31)
      expect(d2.trusted?).to be true
    end
  end

  describe "creating" do
    it "should create a new device with a unique mac address" do
      m="00:01:02:44:55:66"
      t1 = Device.find_or_create_by_mac(m)
      expect(t1).to_not be_nil
      expect(t1.eui64).to eq(m)
    end

    it "should not create a duplicate when mac address repeated" do
      m="00:01:02:44:55:66"
      t1 = Device.find_or_create_by_mac(m)
      expect(t1).to_not be_nil
      expect(t1.eui64).to eq(m)

      t2 = Device.find_or_create_by_mac(m)
      expect(t2).to    eq(t1)
      expect(t2.eui64).to eq(m)
    end
  end

  describe "state" do
    it "with nil firewall_rules should have empty firewall rules" do
      t1 = Device.create
      expect(t1.empty_firewall_rules?).to be true
    end

    it "with zero-length firewall_rules should have empty firewall rules" do
      t1 = Device.create
      t1.firewall_rule_names = []
      expect(t1.empty_firewall_rules?).to be true
    end

    it "should consider a device newly added, if it is not deleted, but has empty rule_names" do
      toaster = devices(:toaster1)
      expect(toaster).to be_need_activation
    end

    it "should consider a device newly deleted, if marked deleted, but has non-empty rule_names" do
      microwave = devices(:microwave1)
      expect(microwave).to be_need_deactivation
    end

    it "should consider a device quanranteed, if not deleted, " do
      fridge = devices(:stinky_fridge)
      expect(fridge).to be_need_quaranteeing
    end

    it "should cause the MUD policy to be removed" do
      thing1 = devices(:stinky_fridge)
      thing1.deleted!

      expect(IO.read("tmp/toaster_load.tout").size).to be > 0
    end

  end

  describe "enrollment" do
    it "should allocate an ACP address" do
      b = devices(:jadaf20001)
      expect(b.acp_prefix).to be_blank
      b.acp_address_allocate!
      expect(b.acp_prefix).to eq("fd73:9fc2:3c34:4011:2233:4455:0000:0000/120")
      expect(b.rfc822Name).to eq("rfc8994+fd739fc23c3440112233445500000000+@acp.example.com")
    end

    it "should generate an appropriate CSRattributes object with the otherName" do
      b = devices(:bulb1)
      b.acp_address_allocate!

      attr = b.csr_attributes.to_der

      File.open("tmp/csr_bulb1.csrattr.der", "wb") do |f|
        f.write attr
      end

      #puts attr.unpack("H*")
      c0 = CSRAttributes.from_der(attr)
      expect(c0).to_not be_nil
      expect(attr).to eq("0d0b\x06\t*\x86H\x86\xF7\r\x01\t\x0E1U0S\x06\x03U\x1D\x11\x01\x01\xFF\x04I\xA0G0E\x06\b+\x06\x01\x05\x05\a\b\n\f9rfc8994+fd739fc23c3440112233445500000000+@acp.example.com".b)

      # now decode it again to prove library can round trip things.
      rfc822Name = c0.find_rfc822Name
      expect(rfc822Name).to include("acp.example.com")
    end

    it "should generate an LDevID signed by domain authority" do
      b = devices(:bulb1)
      expect(b.ldevid).to be_blank

      csrio = IO::read("spec/files/csr_bulb1.der")
      csr   = OpenSSL::X509::Request.new(csrio)
      b.create_ldevid_from_csr(csr)
      expect(b.ldevid).to_not be_blank
    end

    it "should generate an RSA LDevID signed by domain authority RSA key" do
      b = devices(:bulb1)
      expect(b.ldevid).to be_blank

      #FountainKeys.ca.domain_curve = "prime256v1"


      csrio = IO::read("spec/files/csr_bulb1.der")
      csr   = OpenSSL::X509::Request.new(csrio)
      b.create_ldevid_from_csr(csr)
      expect(b.ldevid).to_not be_blank
    end

    it "should generate an rfc822name extension" do
      b = devices(:bulb1)
      b.acp_address_allocate!
      expect(b.rfc822Name).to eq("rfc8994+fd739fc23c3440112233445500000000+@acp.example.com")
      ef = OpenSSL::X509::ExtensionFactory.new
      rfcName=ef.create_extension("subjectAltName",
                                  sprintf("email:%s",
                                          b.rfc822Name),
                                  false)
      expect(rfcName).to_not be_nil
    end

  end

end
