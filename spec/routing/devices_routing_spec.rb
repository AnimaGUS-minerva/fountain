require "rails_helper"

RSpec.describe DevicesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/devices").to route_to("controller"=>"devices",
                                           "action"    =>"index")
    end

    it "routes to #new" do
      expect(:get => "/devices/new").to route_to("controller"=>"devices",
                                           "action"    => "new")
    end

    it "routes to #show" do
      expect(:get => "/devices/1").to route_to("controller"=>"devices",
                                           "action"    => "show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/devices/1/edit").to route_to("controller"=>"devices",
                                           "action"    => "edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/devices").to route_to("controller"=>"devices",
                                           "action"    => "create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/devices/1").to route_to("controller"=>"devices",
                                           "action"    => "update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/devices/1").to route_to("controller"=>"devices",
                                           "action"    => "update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/devices/1").to route_to("controller"=>"devices",
                                           "action"    => "destroy", :id => "1")
    end

  end
end
