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

  describe "receiving vouchers" do
    it "should read a sample voucher from a file" do
      voucher_binary=IO::read(File.join("spec","files","voucher_jada123456789.vch"))

      v1 = CoseVoucher.from_voucher(:cose, voucher_binary)
      expect(v1).to proximity
      expect(v1.serialNumber).to eq('JADA123456789')
      expect(v1.nonce).to        eq('abcd12345')
    end


    it "should create voucher object and place the signed data in it" do
      voucher_base64 = IO::read(File.join("spec","files","voucher_JADA_f2-00-01.pkcs"))
      voucher_binary = Base64.decode64(voucher_base64)

      v1 = CmsVoucher.from_voucher(:pkcs7, voucher_binary)

      expect(v1.node).to eq(nodes(:jadaf20001))
      expect(v1).to_not be_proximity
    end

    it "should create constrained voucher object and place the signed data in it" do
      voucher_base64 = IO::read(File.join("spec","files","voucher_00-D0-E5-01-00-09.vch"))
      voucher_binary = Base64.decode64(voucher_base64)

      v1 = CmsVoucher.from_voucher(:pkcs7, voucher_binary)

      expect(v1.node).to eq(nodes(:jadaf20001))
    end

    it "should get a voucher format error on empty voucher object" do
      voucher_base64 = IO::read(File.join("spec","files","voucher_EMPTY.pkcs"))
      voucher_binary = Base64.decode64(voucher_base64)

      expect {
        v1 = Voucher.from_voucher(:pkcs7, voucher_binary)
      }.to raise_exception(Voucher::VoucherFormatError)
    end
  end


end
