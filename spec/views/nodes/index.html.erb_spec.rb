require 'rails_helper'

RSpec.describe "nodes/index", type: :view do
  before(:each) do
    assign(:nodes, [
      Node.create!(
        :name => "MyText",
        :fqdn => "MyFQDN",
        :eui64 => "MyEUI64",
        :device_type_id => 1,
        :manufacturer_id => 2,
        :idevid => "MyIDEVID"
      ),
      Node.create!(
        :name => "MyText",
        :fqdn => "MyFQDN",
        :eui64 => "MyEUI64",
        :device_type_id => 1,
        :manufacturer_id => 2,
        :idevid => "MyIDEVID"
      )
    ])
  end

  it "renders a list of nodes" do
    render
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => "MyFQDN".to_s, :count => 2
    assert_select "tr>td", :text => "MyEUI64".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => "MyIDEVID".to_s, :count => 2
  end
end
