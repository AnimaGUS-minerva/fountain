require 'rails_helper'

RSpec.describe VoucherRequest, type: :model do
  fixtures :all

  describe "relationships" do
    it "should have a manufacturer" do
      vr1=voucher_requests(vr1)
      expect(vr1.node).to         exist
      expect(vr1.manufacturer).to exist
    end
  end
end
