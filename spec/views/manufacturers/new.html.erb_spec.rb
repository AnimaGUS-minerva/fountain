require 'rails_helper'

RSpec.describe "manufacturers/new", type: :view do
  before(:each) do
    assign(:manufacturer, Manufacturer.new(
      :name => "MyText"
    ))
  end

  it "renders new manufacturer form" do
    render

    assert_select "form[action=?][method=?]", manufacturers_path, "post" do

      assert_select "textarea#manufacturer_name[name=?]", "manufacturer[name]"
    end
  end
end
