require 'rails_helper'

RSpec.describe Voucher, type: :model do
  fixtures :all

  describe "relationships" do
    it "should have an associated MASA" do
      v1 = vouchers(:voucher1)
      expect(v1.manufacturer).to be_present
    end

    it "should have an associated MASA" do
      v1 = vouchers(:voucher1)
      expect(v1.voucher_request).to be_present
    end
  end

  describe "receiving" do
    it "should raise an exception when reading a voucher without public key" do
      voucher_binary=IO::read(File.join("spec","files","voucher_jada123456789_bad.vch"))

      expect {
        v1 = CoseVoucher.from_voucher(:cose, voucher_binary)
      }.to raise_error(Chariwt::Voucher::MissingPublicKey)
    end

    it "should read a sample voucher from a file" do
      # this input comes from chariwt/tmp/voucher_jada123456789.vch
      voucher_binary=IO::read(File.join("spec","files","voucher_jada123456789.vch"))

      v1 = CoseVoucher.from_voucher(:cose, voucher_binary)
      expect(v1).to               be_proximity
      expect(v1.serial_number).to eq('JADA123456789')
      expect(v1.nonce).to         eq('abcd12345')
    end


    it "should create voucher object and place the signed data in it" do
      voucher_base64 = IO::read(File.join("spec","files","voucher_JADA_f2-00-01.pkcs"))
      voucher_binary = Base64.decode64(voucher_base64)

      v1 = CmsVoucher.from_voucher(:pkcs7, voucher_binary)

      expect(v1.node).to eq(nodes(:jadaf20001))
      expect(v1).to_not be_proximity
    end

    it "should find a constrained voucher in the specification" do
      cv2 = vouchers(:cv2)
      expect(cv2.node).to eq(nodes(:n3))
    end

    it "should load a constrained voucher representation, and create a database object for it" do
      voucher_binary = IO::read(File.join("spec","files","voucher_jada123456789.vch"))
      v1 = CoseVoucher.from_voucher(:cose, voucher_binary)
      expect(v1.node).to eq(nodes(:n3))
    end

    it "should get a voucher format error on empty voucher object" do
      voucher_base64 = IO::read(File.join("spec","files","voucher_EMPTY.pkcs"))
      voucher_binary = Base64.decode64(voucher_base64)

      expect {
        v1 = Voucher.from_voucher(:pkcs7, voucher_binary)
      }.to raise_exception(Voucher::VoucherFormatError)
    end

    it "should process a multipart voucher response into two parts" do
      voucher_mime = Mail.read(File.join("spec","files","voucher_00-D0-E5-F2-10-03.mvch"))

      expect(voucher_mime).to_not be_nil

      expect(voucher_mime.parts[0]).to_not be_nil
      expect(voucher_mime.parts[0].content_type).to eq("application/voucher-cose+cbor")
      expect(voucher_mime.parts[1]).to_not be_nil
      expect(voucher_mime.parts[1].content_type).to eq("application/pkcs7-mime; smime-type=certs-only")
    end


  end


end
