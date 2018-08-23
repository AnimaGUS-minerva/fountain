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

  def mud1_stub(url, filename = nil)
    voucher_request = nil
    result   = ""
    if filename
      result = File.read(filename)
    end
    stub_request(:get, url).
      with(headers: {
             'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
             'Host'=>'highway.sandelman.ca',
           }).
      to_return(status: 200, body: lambda { |request|
                  voucher_request = request.body
                  result},
                headers: {
                  'Content-Type'=>'application/mud+json',
                })
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
      new_url = "https://bigcorp.example.com/product1234/mud.der"
      mud1_stub(new_url)
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
      expect(thing1.name).to_not eq(oname)
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
