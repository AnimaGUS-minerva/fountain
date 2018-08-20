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



end
