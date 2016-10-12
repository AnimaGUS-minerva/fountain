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

end
