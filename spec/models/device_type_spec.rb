require 'rails_helper'

require 'support/mud_toaster'

RSpec.describe DeviceType, type: :model do
  fixtures :all

  describe "relations" do
    it "should have one or more devices" do
      b1 = device_types(:bulbs)
      expect(b1.devices.count).to be >= 1
    end

    it "should have a manufacturer" do
      b1 = device_types(:bulbs)
      expect(b1.manufacturer).to_not be_nil
    end
  end

  describe "mud_url" do
    def toaster_mud
      mud_file = "spec/files/mud/toaster_mud.json"
      mud1_stub("http://example.com/mud/toaster_mud.json", mud_file)
      mud_file
    end

    it "should create new device_type" do
      mud_file     = "spec/files/mud/toaster_mud.json"
      mud_url      = "http://mud1.example.com/mud/toaster_mud.json"
      mud_sig_file = "spec/files/mud/toaster_mud.json.sig"
      mud_sig_url  = "http://mud1.example.com/mud/toaster_mud.json.sig"
      mud1_stub(mud_url,         mud_file)
      mud1_stub_sig(mud_sig_url, mud_sig_file)
      dt = DeviceType.find_or_create_by_mud_url(mud_url)

      expect(dt).to_not be_nil
      expect(dt.mud_url).to     eq(mud_url)
      expect(dt.mud_url_sig).to eq(mud_url + ".sig")
    end

    it "should validate an existing entry" do
      toaster_mud

      mu = device_types(:toasters)
      expect(mu.validate_mud_url).to be true
      expect(mu.mud_url_sig).to_not  be_nil
    end

    it "should load MUD JSON from URL, if not found" do
      toaster_mud

      dt = device_types(:toasters)

      expect(dt.mud_json).to_not be_nil
      expect(dt.mud_json_ietf).to_not be_nil
      expect(dt.mud_json_ietf["mud-version"]).to eq(1)
    end
  end

end
