require 'rails_helper'

RSpec.describe "manufacturers/index", type: :view do
  before(:each) do
    assign(:manufacturers, [
      Manufacturer.create!(
        :name => "MyText"
      ),
      Manufacturer.create!(
        :name => "MyText"
      )
    ])
  end

  it "renders a list of manufacturers" do
    render
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end
