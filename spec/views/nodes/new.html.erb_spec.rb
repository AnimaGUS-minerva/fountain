require 'rails_helper'

RSpec.describe "nodes/new", type: :view do
  before(:each) do
    assign(:node, Node.new(
      :name => "MyText",
      :fqdn => "MyText",
      :eui64 => "MyText",
      :device_type_id => 1,
      :manufacturer_id => 1,
      :idevid => "MyText"
    ))
  end

  it "renders new node form" do
    render

    assert_select "form[action=?][method=?]", nodes_path, "post" do

      assert_select "textarea#node_name[name=?]", "node[name]"

      assert_select "textarea#node_fqdn[name=?]", "node[fqdn]"

      assert_select "textarea#node_eui64[name=?]", "node[eui64]"

      assert_select "input#node_device_type_id[name=?]", "node[device_type_id]"

      assert_select "input#node_manufacturer_id[name=?]", "node[manufacturer_id]"

      assert_select "textarea#node_idevid[name=?]", "node[idevid]"
    end
  end
end
