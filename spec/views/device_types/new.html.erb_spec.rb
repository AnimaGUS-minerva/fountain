require 'rails_helper'

RSpec.describe "device_types/new", type: :view do
  before(:each) do
    assign(:device_type, DeviceType.new(
      :name => "MyText"
    ))
  end

  it "renders new device_type form" do
    render

    assert_select "form[action=?][method=?]", device_types_path, "post" do

      assert_select "textarea#device_type_name[name=?]", "device_type[name]"
    end
  end
end
