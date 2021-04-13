require "rails_helper"

RSpec.describe EstController, type: :routing do
  describe "routing" do

    it "should map /.well-known/brski/requestvoucher to #requestvoucher" do
      expect(:post => "/.well-known/brski/requestvoucher").to route_to("est#requestvoucher")
    end

  end
end
