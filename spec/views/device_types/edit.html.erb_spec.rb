require 'rails_helper'

RSpec.describe "device_types/edit", type: :view do
  before(:each) do
    @device_type = assign(:device_type, DeviceType.create!(
      :name => "MyText"
    ))
  end

  it "renders the edit device_type form" do
    render

    assert_select "form[action=?][method=?]", device_type_path(@device_type), "post" do

      assert_select "textarea#device_type_name[name=?]", "device_type[name]"
    end
  end
end
