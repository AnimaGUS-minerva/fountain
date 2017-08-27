require 'rails_helper'

RSpec.describe Voucher, type: :model do
  fixtures :all

  describe "relationships" do
    it "should have an associated MASA" do
      v1 = vouchers(:voucher1)
      expect(v1.manufacturer).to be_present
    end
    it "should have an associated MASA" do
      v1 = vouchers(:voucher1)
      expect(v1.voucher_request).to be_present
    end
  end
end
