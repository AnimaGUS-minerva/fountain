require 'rails_helper'

RSpec.describe DeviceType, type: :model do
  fixtures :all

  describe "relations" do
    it "should have one or more nodes" do
      b1 = device_types(:bulbs)
      expect(b1.nodes.count).to be >= 1
    end
  end
end
