require 'rails_helper'

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
end
