require 'rails_helper'

RSpec.describe Node, type: :model do
  fixtures :all

  describe "relations" do
    it "should have a manufacturer" do
      b1 = nodes(:bulb1)
      expect(b1.manufacturer).to be_truthy
    end

    it "should have a device type" do
      b1 = nodes(:bulb1)
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
      t1 = nodes(:thing1)
      t1.increment_bytes(:incoming, 10)
      expect(t1.traffic_counts["bytes"][0]).to eq(1244)
    end

    it "should init an empty device with zero counts" do
      t1 = Node.create
      t1.save
      expect(t1.traffic_counts["bytes"][0]).to   eq(0)
      expect(t1.traffic_counts["bytes"][1]).to   eq(0)
      expect(t1.traffic_counts["packets"][0]).to eq(0)
      expect(t1.traffic_counts["packets"][1]).to eq(0)
    end
  end

end
