require 'rails_helper'

require 'support/mud_toaster'

RSpec.describe Device, type: :model do
  fixtures :all

  before(:each) do
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
  end

  describe "GRASP queries" do
    it "should parse a GRASP message into a series of objects" do
      File.open(Rails.root.join("spec","fixtures","files","43-6join-grasp.dump"),"rb") do |infile|
        File.open(Rails.root.join("tmp","out1.dump"), "wb") do |out|
          gs = GraspServer.new(infile, out)
          gs.process
        end
      end
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

      mwave.do_activation!
      expect(File.exists?("tmp/mudfiles/00005.json")).to be true
    end

    it "should setup of a new device_type given a new mud_url" do
      mu = toaster_mud
      toaster = devices(:toaster1)
      expect(toaster.device_type).to     be_nil

      toaster.mud_url = mu
      expect(toaster.device_type).to_not be_nil
    end

    it "should communicate a new mud entry to the mud-super" do
      toaster = devices(:toaster1)
      toaster.mud_url = toaster_mud

      expect(toaster.device_type).to_not be_nil
      expect(toaster).to be_activated
    end

    it "should communicate mud entry using a socket" do
      toaster = devices(:toaster1)
      toaster.mud_url = toaster_mud
      expect(toaster.device_type).to_not be_nil
      expect(toaster.mud_install_job).to_not be_nil
    end

    it "should save mud-filter names to device_type" do
      toaster = devices(:toaster1)
      toaster.mud_url = toaster_mud
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
  end

end
