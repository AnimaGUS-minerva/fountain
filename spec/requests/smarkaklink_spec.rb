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
    @env = nil
  end

  describe "request voucher-request" do

    def do_rvr_post_1502(json)
      @env ||= Hash.new
      @env["SSL_CLIENT_CERT"] = smarkaklink_client_1502
      @env["HTTP_ACCEPT"]  = CmsVoucherRequest::CMS_VOUCHER_REQUEST_TYPE
      @env["CONTENT_TYPE"] = "application/json"
      post '/.well-known/est/requestvoucherrequest', :params => json, :headers => @env
    end

    it "should accept a /requestvoucherrequest from a smartphone" do
      # get the Base64 of the parboiled signed request
      bodyjs = { "ietf:request-voucher-request" =>
                   { "voucher-request-challenge" => IO::read("spec/files/smarkaklink_req-challenge-01.b64") }
               }.to_json

      do_rvr_post_1502(bodyjs)

      expect(response).to have_http_status(200)
    end

    it "should reject a /requestvoucherrequest with bad JSON top-level" do
      # get the Base64 of the parboiled signed request
      bodyjs = { "blah": "hello" }.to_json

      do_rvr_post_1502(bodyjs)
      expect(response).to have_http_status(400)
      expect(response['Text']).to include("request-voucher-request")
    end

    it "should reject a /requestvoucherrequest with a missing voucher-challenge-nonce" do
      # get the Base64 of the parboiled signed request
      bodyjs = { "ietf:request-voucher-request":
                   { "hello": "there" }
               }.to_json

      do_rvr_post_1502(bodyjs)
      expect(response).to have_http_status(400)
      expect(response['Text']).to include("missing voucher-challenge-nonce")
    end
  end


end
