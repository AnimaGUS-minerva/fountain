require 'rails_helper'

RSpec.describe "Administrators", type: :request do
  fixtures :all

  def ssl_headers(client)
    env = Hash.new
    env["SSL_CLIENT_CERT"] = client.certificate.to_pem
    env
  end

  describe "logins" do
    it "should get authenticated with a certificate" do
      ad1 = administrators(:admin1)

      get "/administrators/#{ad1.id}.json", :headers => ssl_headers(ad1)
      expect(response).to have_http_status(200)
    end

    it "should get a 401, is called without a certificate" do
      ad1 = administrators(:admin1)

      get "/administrators/#{ad1.id}.json"
      expect(response).to have_http_status(401)
    end

  end


end
