require 'rails_helper'
require 'support/mud_toaster'


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
      get url_for(thing1), :headers => ssl_headers(nil)
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

  describe "create" do
    it "should permit an administrator to create a new device" do
      post devices_path, :headers => ssl_headers(administrators(:admin1)),
           :params  => { :device => { :name => "Downstairs Thermostat",
                                      :fqdn => "new.example.com",
                                    }}
      expect(response).to have_http_status(201)
    end

    it "should permit new device by mac_addr" do
      post devices_path, :headers => ssl_headers(administrators(:admin1)),
           :params  => { :device => { :eui64 => "00:11:33:88:77:44",
                                      :fqdn => "new.example.com",
                                    }}
      expect(response).to have_http_status(201)
    end

    it "should permit new device by mac_addr, but not duplicate it" do
      post devices_path, :headers => ssl_headers(administrators(:admin1)),
           :params  => { :device => { :eui64 => "00:11:33:88:77:44",
                                      :fqdn => "new.example.com",
                                    }}
      expect(response).to have_http_status(201)
      dev1 = assigns(:object)
      location = response.headers["Location"]

      post devices_path, :headers => ssl_headers(administrators(:admin1)),
           :params  => { :device => { :eui64 => "00:11:33:88:77:44",
                                      :fqdn => "newer.example.com",
                                    }}
      expect(response).to                     have_http_status(201)
      expect(assigns(:object).id).to          eq(dev1.id)
      expect(response.headers["Location"]).to eq(location)
    end

  end

  describe "access" do
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

  describe "update" do
    it "should permit updates by administrator" do
      thing1 = devices(:thing1)
      oname  = thing1.name
      put url_for(thing1), { :headers => ssl_headers(administrators(:admin1)),
                             :params  => { :device => { :name => "Downstairs Thermostat" }}}
      expect(response).to have_http_status(200)
      thing1.reload
      expect(thing1.name).to_not eq(oname)
    end
    it "should deny updates by non-administrators" do
      thing1 = devices(:thing1)
      oname  = thing1.name
      put url_for(thing1), { :headers => ssl_headers(administrators(:frank2)),
                             :params  => { :device => { :name => "Downstairs Thermostat" }}}
      expect(response).to have_http_status(403)
      thing1.reload
      expect(thing1.name).to eq(oname)
    end
    it "should deny updates when no login" do
      thing1 = devices(:thing1)
      oname  = thing1.name
      put url_for(thing1), { :headers => ssl_headers(nil),
                             :params  => { :device => { :name => "Downstairs Thermostat" }}}
      expect(response).to have_http_status(401)
      thing1.reload
      expect(thing1.name).to eq(oname)
    end

    it "should permit updates to fqdn" do
      thing1 = devices(:thing1)
      oname   = thing1.name
      old_fqdn = thing1.fqdn
      put url_for(thing1), { :headers => ssl_headers(administrators(:admin1)),
                             :params  => { :device => { :name => "Downstairs Thermostat",
                                                        :fqdn => "new.example.com",
                                                      }}}
      expect(response).to have_http_status(200)

      # get the object again and verify that it changed appropriately
      thing1.reload
      expect(thing1.name).to_not eq(oname)
      expect(thing1.fqdn).to_not eq(old_fqdn)
    end

    it "should permit updates to eui64" do
      thing1 = devices(:thing1)
      oname   = thing1.name
      old_eui64 = thing1.eui64
      put url_for(thing1), { :headers => ssl_headers(administrators(:admin1)),
                             :params  => { :device => { :name => "Downstairs Thermostat",
                                                        :eui64 => "new.example.com",
                                                      }}}
      expect(response).to have_http_status(200)

      # get the object again and verify that it changed appropriately
      thing1.reload
      expect(thing1.name).to_not eq(oname)
      expect(thing1.eui64).to_not eq(old_eui64)
    end

    it "should permit updates to mud_url, loading the new mud policy" do
      @mms = MockMudSocket.new("spec/files/mud/toaster_load.tin",
                               "tmp/toaster_load.tout")

      new_url = "https://bigcorp.example.com/product1234/thermostat-example.json"
      mud1_stub(new_url, "spec/files/mud/thermostat-example.json")
      mud1_stub_sig(new_url+".sig", "spec/files/mud/thermostat-example.json.sig")

      thing1 = devices(:thing1)
      oname   = thing1.name
      old_mud_url = thing1.mud_url
      put url_for(thing1), { :headers => ssl_headers(administrators(:admin1)),
                             :params  => { :device => { :name => "Downstairs Thermostat",
                                                        :mud_url => new_url,
                                                      }}}
      expect(response).to have_http_status(200)

      # get the object again and verify that it changed appropriately
      thing1.reload
      expect(thing1.name).to_not    eq(oname)
      expect(thing1.mud_url).to_not eq(old_mud_url)
    end

    it "should silently ignore attempts to update traffic_counts" do
      thing1 = devices(:thing1)
      oname   = thing1.name
      old_tcounts = thing1.traffic_counts
      put url_for(thing1), { :headers => ssl_headers(administrators(:admin1)),
                             :params  => { :device => { :name => "Downstairs Thermostat",
                                                        :traffic_counts => { "planets" => [ 0,0 ] }
                                                      }}}
      expect(response).to have_http_status(200)

      # get the object again and verify that it changed appropriately
      thing1.reload
      expect(thing1.name).to_not eq(oname)
      expect(thing1.traffic_counts).to  eq(old_tcounts)
    end


  end



end
