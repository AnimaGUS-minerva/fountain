require 'rails_helper'

RSpec.describe Administrator, type: :model do
  fixtures :all

  it "should have an admin bit" do
    admin1 = administrators(:admin1)
    expect(admin1.admin).to   be true
    expect(admin1.enabled).to be true
    expect(admin1.prospective).to be false
  end
end
