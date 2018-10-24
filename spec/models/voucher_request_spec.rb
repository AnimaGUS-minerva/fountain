require 'rails_helper'

RSpec.describe VoucherRequest, type: :model do
  fixtures :all

  before(:each) do
    FountainKeys.ca.certdir = Rails.root.join('spec','files','cert')
  end

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
      vr1.created_at = '2017-09-15'.to_datetime
      # result is a BASE64 encoded PKCS7 object
      expect(vr1.nonce).to eq("abcd1234")
      expect(vr1.registrar_voucher_request).to_not be_nil

      smime = vr1.registrar_voucher_request

      expect(Chariwt.cmp_pkcs_file(smime,
                                   "voucher_request-00-D0-E5-F2-00-02")).to be_truthy

      expect(vr1.signing_cert.subject.to_s).to eq("/DC=ca/DC=sandelman/CN=localhost")
      expect(vr1.masa_url).to eq("https://highway.sandelman.ca/")
    end
  end

  describe "sending requests" do
    it "should request a voucher from the MASA" do
      voucher1_base64 = IO::read(File::join(Rails.root, "spec", "files", "voucher_081196FFFE0181E0.pkcs"))

      voucher_request = nil
      @time_now = Time.at(1507671037)  # Oct 10 17:30:44 EDT 2017
      allow(Time).to receive(:now).and_return(@time_now)

      stub_request(:post, "https://highway.sandelman.ca/.well-known/est/requestvoucher").
        with(headers: {'Accept'=>['*/*', 'application/pkcs7-mime; smime-type=voucher'],
                       'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                       'Content-Type'=>'application/pkcs7-mime; smime-type=voucher-request',
                       'Host'=>'highway.sandelman.ca',
                       'User-Agent'=>'Ruby'}).
         to_return(status: 200, body: lambda { |request|
                    voucher_request = request.body
                    voucher1_base64},
                   headers: {
                   'Content-Type' => 'application/pkcs7-mime; smime-type=voucher'})

      vr1= voucher_requests(:vr1)
      v1 = vr1.get_voucher
      expect(v1.manufacturer).to eq(vr1.manufacturer)

      expect(Chariwt.cmp_pkcs_file(voucher_request,
                                   "model_request_081196FFFE0181E0")).to be_truthy
    end

    it "should process content-type to extract voucher/response" do
      vr1 = voucher_requests(:vr1)
      bodystr = IO::read(File.join('spec', 'files', 'voucher_081196FFFE0181E0.pkcs'))
      voucher = vr1.process_content_type('application/pkcs7-mime; smime-type=voucher', bodystr)
      expect(voucher).to_not be_nil
      expect(voucher.type).to eq("CmsVoucher")
      expect(voucher.assertion).to eq("logged")
    end

    it "should store the broken voucher responses into the vr.status field when missing public key" do
      pending "more to write"
    end

    it "should have a dozen voucher responses which are broken/mis-formatted" do
      pending "something to write"
      vr1= nil
      expect(vr1).to_not be_nil
    end

  end

  describe "certificates" do
    it "should find the MASA URL from the certificate" do
      vr2 = VoucherRequest.new
      vr2.tls_clientcert = IO.binread("spec/certs/00-D0-E5-02-00-20.crt")
      vr2.discover_manufacturer
      expect(vr2.manufacturer).to eq(manufacturers(:honeydukes))
    end
  end

  describe "vouchers" do
    it "should send a signed request to the indicated MASA" do
      vr1=voucher_requests(:vr1)

    end
  end
end
