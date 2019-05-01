require 'rails_helper'
require 'support/pem_data'

RSpec.describe "Smarkaklink", type: :request do
  fixtures :all

  def temporary_key
    ECDSA::Format::IntegerOctetString.decode(["20DB1328B01EBB78122CE86D5B1A3A097EC44EAC603FD5F60108EDF98EA81393"].pack("H*"))
  end

  # set up JRC keys to testing ones
  before(:each) do
    SystemVariable.setbool(:open_registrar, false)
    FountainKeys.ca.certdir = Rails.root.join('spec','files','cert')
  end

  describe "request voucher-request" do
    it "should accept a /requestvoucherrequest from a smartphone" do
      # get the Base64 of the parboiled signed request
      bodyjs = { "ietf:request-voucher-request" =>
                   { "voucher-request-challenge" => IO::read("spec/files/smarkaklink_req-challenge-01.b64") }
               }.to_json

      @env = Hash.new
      @env["SSL_CLIENT_CERT"] = smarkaklink_client_1502
      @env["HTTP_ACCEPT"]  = "application/voucher-cms+json"
      @env["CONTENT_TYPE"] = "application/voucher-cms+json"
      post '/.well-known/est/requestvoucherrequest', :params => bodyjs, :headers => @env

      expect(response).to have_http_status(200)
    end
  end


end
