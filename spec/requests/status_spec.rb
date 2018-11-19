# spec/requests/todos_spec.rb
require 'rails_helper'

RSpec.describe 'BRSKI status API', type: :request do

  describe "status request" do
    it "GET /status" do
      get "/status"

      expect(response).to have_http_status(200)
      expect(response['Content-Type']).to include("text/html")
    end

    it "GET /status" do
      get "/status.json"

      expect(response).to have_http_status(200)
      expect(response['Content-Type']).to include("application/json")
    end
  end

end
