require 'rails_helper'

RSpec.describe "Est", type: :request do

  describe "voucher request" do
    it "works! (now write some real specs)" do

      post "/.well-known/est/requestvoucher"
      expect(response).to have_http_status(200)
    end
  end
end
