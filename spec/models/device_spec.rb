require 'rails_helper'

require 'support/mud_toaster'

RSpec.describe Device, type: :model do
  fixtures :all

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

  describe "devices" do
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

    it "with nil firewall_rules should have empty firewall rules" do
      t1 = Device.create
      expect(t1.empty_firewall_rules?).to be true
    end

    it "with zero-length firewall_rules should have empty firewall rules" do
      t1 = Device.create
      t1.firewall_rule_names = []
      expect(t1.empty_firewall_rules?).to be true
    end

    it "should setup of a new device_type given a new mud_url" do
      mu = toaster_mud
      toaster = devices(:toaster1)
      expect(toaster.device_type).to     be_nil

      toaster.mud_url = mu
      expect(toaster.device_type).to_not be_nil
    end

    it "should consider a device newly added, if it is not deleted, but has empty rule_names" do
      toaster = devices(:toaster1)
      expect(toaster).to be_need_activation
    end

    it "should consider a device newly deleted, if marked deleted, but has non-empty rule_names" do
      microwave = devices(:microwave)
      expect(microwave).to be_need_deactivation
    end

    it "should consider a device quanranteed, if not deleted, " do
      fridge = devices(:stinky_fridge)
      expect(fridge).to be_need_quaranteeing
    end


  end

end
