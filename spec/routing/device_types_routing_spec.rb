require "rails_helper"

RSpec.describe DeviceTypesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/device_types").to route_to(
                                           concerts: :active_scaffold,
                                           controller: 'device_types',
                                           action: 'index'
                                         )
    end

    it "routes to #new" do
      expect(:get => "/device_types/new").to route_to(
                                           concerts: :active_scaffold,
                                           controller: 'device_types',
                                           action: 'new')
    end

    it "routes to #show" do
      expect(:get => "/device_types/1").to route_to(
                                           concerts: :active_scaffold,
                                           controller: 'device_types',
                                           action: 'show',
                                           id: "1")
    end

    it "routes to #edit" do
      expect(:get => "/device_types/1/edit").to route_to(
                                           concerts: :active_scaffold,
                                           controller: 'device_types',
                                           action: 'edit', id: "1")
    end

    it "routes to #create" do
      expect(:post => "/device_types").to route_to(
                                           concerts: :active_scaffold,
                                           controller: 'device_types',
                                           action: 'create')
    end

    it "routes to #update via PUT" do
      expect(:put => "/device_types/1").to route_to(
                                           concerts: :active_scaffold,
                                           controller: 'device_types',
                                           action: 'update', id: "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/device_types/1").to route_to(
                                           concerts: :active_scaffold,
                                           controller: 'device_types',
                                           action: 'update', id: "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/device_types/1").to route_to(
                                           concerts: :active_scaffold,
                                           controller: 'device_types',
                                           action: 'destroy', id: "1")
    end

  end
end
