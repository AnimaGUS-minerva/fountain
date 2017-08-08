require "rails_helper"

RSpec.describe EstController, type: :routing do
  describe "routing" do


    it "routes to #show" do
      expect(:get => "/ests/1").to route_to("ests#show", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/ests").to route_to("ests#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/ests/1").to route_to("ests#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/ests/1").to route_to("ests#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/ests/1").to route_to("ests#destroy", :id => "1")
    end

  end
end
