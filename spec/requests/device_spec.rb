require 'rails_helper'

RSpec.describe "Devices", type: :request do
  fixtures :all

  def ssl_headers(client = nil)
    env = Hash.new
    if(client)
      env["SSL_CLIENT_CERT"] = client.certificate.to_pem
    end
    env['ACCEPT'] = 'application/json'
    env
  end

  describe "permissions" do
    it "should fail with no login" do
      thing1 = devices(:thing1)
      get url_for(thing1), :headers => ssl_headers()
      expect(response).to have_http_status(401)
    end

    it "should fail when not administrator" do
      thing1 = devices(:thing1)
      get url_for(thing1), :headers => ssl_headers(administrators(:frank2))
      expect(response).to have_http_status(403)
    end

    it "should succeed when admin is enabled" do
      thing1 = devices(:thing1)
      get url_for(thing1), :headers => ssl_headers(administrators(:admin1))
      expect(response).to have_http_status(200)
    end
  end

  describe "devices" do
    it "should show a single device with attributes" do
      thing1 = devices(:thing1)
      get url_for(thing1), :headers => ssl_headers(administrators(:admin1))
      expect(response).to have_http_status(200)
      reply = JSON::parse(response.body)
      expect(reply["device"]).to_not     be_nil
      expect(reply["device"]["name"]).to eq(thing1.name)
    end

    it "should return list of devices" do
      get "/devices", :headers => ssl_headers(administrators(:admin1))
      expect(response).to have_http_status(200)
      reply = JSON::parse(response.body)
      expect(reply["devices"]).to_not  be_nil
      expect(reply["devices"].size).to eq(Device.count)
    end

    it "should reuse list of devices to non-admins" do
      get "/devices", :headers => ssl_headers(administrators(:frank2))
      expect(response).to have_http_status(403)
    end
  end



end
