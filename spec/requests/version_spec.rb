# spec/requests/todos_spec.rb
require 'rails_helper'

RSpec.describe 'Highway version API', type: :request do

  describe "version numbers" do
    it "should return version when asked at /version" do
      get "/version"
      expect(response).to have_http_status(200)
      expect(response['Content-Type']).to include("text/plain")
    end

    it "should return JSON version when asked at /version.json" do
      get "/version.json"
      expect(response).to have_http_status(200)
      expect(response['Content-Type']).to include("application/json")
    end

    it "should return JSON version when asked at /version with accept header" do
      get "/version",  headers: {
            'ACCEPT'       => 'application/json'
          }
      expect(response).to have_http_status(200)
      expect(response['Content-Type']).to include("application/json")
    end
  end

end
