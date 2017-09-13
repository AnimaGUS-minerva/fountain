require 'rails_helper'

RSpec.describe VoucherRequest, type: :model do
  fixtures :all

  describe "relationships" do
    it "should have a manufacturer" do
      vr1=voucher_requests(:vr1)
      expect(vr1.node).to         be_present
      expect(vr1.manufacturer).to be_present
    end
    it "should have a voucher (response)" do
      vr1=voucher_requests(:vr1)
      expect(vr1.vouchers).to      be_present
    end
  end

  describe "signing requests" do
    it "should create a signed voucher request" do
      vr1=voucher_requests(:vr1)
      # result is a BASE64 encoded PKCS7 object
      expect(vr1.registrar_voucher_request_json).to_not be_nil

      # save it for examination elsewhere (and use by MASA tests)
      File.open(File.join("tmp", "vr_#{vr1.device_identifier}.pkcs"), "w") do |f|
        f.puts vr1.registrar_voucher_request_pkcs7
      end

      expect(vr1.owner_cert.subject.to_s).to eq("/DC=ca/DC=sandelman/CN=localhost")
      expect(vr1.masa_url).to eq("https://highway.sandelman.ca/")
    end
  end

  describe "sending requests" do
    it "should request a voucher from the MASA" do
      voucher1_base64 = Base64.encode64(IO::read(File::join(Rails.root, "spec", "files", "voucher_12ea91.pkcs")))
      stub_request(:post, "http://highway.sandelman.ca:443/.well-known/est/voucherrequest").
        with(headers: {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/pkcs7-mime; smime-type=voucher-request', 'Host'=>'highway.sandelman.ca', 'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: voucher1_base64, headers: {
                   'Content-Type' => 'application/pkcs7-mime; smime-type=voucher'})

      vr1= voucher_requests(:vr1)
      v1 = vr1.get_voucher
      expect(v1.manufacturer).to eq(vr1.manufacturer)
    end

    it "should process content-type to extract voucher/response" do
      vr1= voucher_requests(:vr1)
      expect(vr1.process_content_type('application/pkcs7-mime; smime-type=voucher')).to be_truthy
      expect(vr1).to be_response_pkcs7
      expect(vr1).to be_response_voucher
      expect(vr1.response_type).to eq(:pkcs7_voucher)
    end

  end

  describe "certificates" do
    it "should find the MASA URL from the certificate" do
      vr2 = VoucherRequest.new
      vr2.tls_clientcert = IO.binread("spec/certs/12-00-00-66-4D-02.crt")
      vr2.discover_manufacturer
      expect(vr2.manufacturer).to eq(manufacturers(:widget1))
    end
  end

  describe "vouchers" do
    it "should send a signed request to the indicated MASA" do
      vr1=voucher_requests(:vr1)

    end
  end
end
