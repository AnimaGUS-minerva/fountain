require 'rails_helper'

require 'support/mud_toaster'
require 'support/pem_data'

RSpec.describe CSRAttributes do
  it "should process CSR attributes from RFC7030" do
    test_der="\x30\x41\x06\x09\x2a\x86\x48\x86\xf7\x0d\x01\x09\x07\x30\x12\x06\x07\x2a\x86\x48\xce\x3d" \
               "\x02\x01\x31\x07\x06\x05\x2b\x81\x04\x00\x22\x30\x16\x06\x09\x2a\x86\x48\x86\xf7\x0d\x01" \
               "\x09\x0e\x31\x09\x06\x07\x2b\x06\x01\x01\x01\x01\x16\x06\x08\x2a\x86\x48\xce\x3d\x04\x03" \
               "\x03".b

    asn1 = OpenSSL::ASN1.decode(test_der)
    expect(asn1).to be_a OpenSSL::ASN1::Sequence
    expect(asn1.value.length).to eq(4)

    c1 = CSRAttributes.from_der(test_der)
    a1 = OpenSSL::ASN1::ObjectId.new("id-ecPublicKey")
    attr1=c1.find_attr(a1)
    expect(attr1.length).to eq(1)
    expect(attr1.first.sn).to eq("secp384r1")
  end

end

