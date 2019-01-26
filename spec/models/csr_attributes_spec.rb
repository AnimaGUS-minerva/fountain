require 'rails_helper'

require 'support/mud_toaster'
require 'support/pem_data'

RSpec.describe CSRAttributes do

  def test_der
    "\x30\x41\x06\x09\x2a\x86\x48\x86\xf7\x0d\x01\x09\x07\x30\x12\x06\x07\x2a\x86\x48\xce\x3d" \
               "\x02\x01\x31\x07\x06\x05\x2b\x81\x04\x00\x22\x30\x16\x06\x09\x2a\x86\x48\x86\xf7\x0d\x01" \
               "\x09\x0e\x31\x09\x06\x07\x2b\x06\x01\x01\x01\x01\x16\x06\x08\x2a\x86\x48\xce\x3d\x04\x03" \
               "\x03".b
  end

  it "should process CSR attributes from RFC7030" do
    asn1 = OpenSSL::ASN1.decode(test_der)
    expect(asn1).to be_a OpenSSL::ASN1::Sequence
    expect(asn1.value.length).to eq(4)

    c1 = CSRAttributes.from_der(test_der)
    a1 = OpenSSL::ASN1::ObjectId.new("id-ecPublicKey")
    attr1=c1.find_attr(a1)
    expect(attr1.length).to eq(1)
    expect(attr1.first.sn).to eq("secp384r1")

    a2 = OpenSSL::ASN1::ObjectId.new("extReq")
    attr2=c1.find_attr(a2)
    expect(attr2.length).to eq(1)
    expect(attr2.first.value).to eq("1.3.6.1.1.1.1.22")
  end

  it "should create a CSR attribute file" do
    c1 = CSRAttributes.new
    c1.add_oid("challengePassword")
    c1.add_attr("id-ecPublicKey", OpenSSL::ASN1::ObjectId.new("secp384r1"))
    c1.add_attr("extReq",         OpenSSL::ASN1::ObjectId.new("1.3.6.1.1.1.1.22"))
    c1.add_oid("ecdsa-with-SHA384")

    new_der = c1.to_der
    expect(new_der).to eq(test_der)

    c0 = CSRAttributes.from_der(new_der)
    expect(c0).to_not be_nil
  end

  it "should create a CSR attribute with a subjectAltName rfc822Name" do
    c1 = CSRAttributes.new
    c1.add_attr("subjectAltName",
                CSRAttributes.rfc822Name("hello@example.com"))

    der=c1.to_der
    #puts der.unpack("H*")
    File.open("tmp/hellobulb0.der", "wb") { |f| f.syswrite der }
    expect(c1.to_der).to eq("0 0\x1E\x06\x03U\x1D\x111\x170\x15\xA2\x13\f\x11hello@example.com".b)
  end

  it "should validate encoding/decoding of CSR attributes" do
    # this exists just to make help identify actual encoding problems
    # that are sometimes burried.
    name = "hello@example.com"
    if false
      a4 = OpenSSL::ASN1::UTF8String.new(name, 2, :EXPLICIT, :CONTEXT_SPECIFIC)
      a3 = OpenSSL::ASN1::Sequence.new([a4])  # make the rfc822Name
      a2 = OpenSSL::ASN1::Set.new([a3])       # make set of SAN
    else
      a2 = CSRAttributes.rfc822Name(name)
    end
    a2tag=OpenSSL::ASN1::ObjectId.new("subjectAltName")
    a1 = OpenSSL::ASN1::Sequence.new([a2tag, a2])  # the subjectAltName attr
    a0 = OpenSSL::ASN1::Sequence.new([a1])  # the sequence of attributes
    der= a0.to_der
    #puts der.unpack("H*")
    File.open("tmp/hellobulb1.der", "wb") { |f| f.syswrite der }

    c0 = CSRAttributes.from_der(der)
    expect(c0).to_not be_nil

  end

  it "should validate encoding/decoding of CSR rfc822name" do
    # this exists just to make help identify actual encoding problems
    # that are sometimes burried.
    a3 = OpenSSL::ASN1::UTF8String.new("rfcSELF+fd739fc23c3440112233445500000000+@acp.example.com", 2, :EXPLICIT, :CONTEXT_SPECIFIC)
    a2 = OpenSSL::ASN1::Set.new([a3])  # make the rfc822Name
    a2tag=OpenSSL::ASN1::ObjectId.new("subjectAltName")
    a1 = OpenSSL::ASN1::Sequence.new([a2tag, a2])  # the subjectAltName attr
    a0 = OpenSSL::ASN1::Sequence.new([a1])  # the sequence of attributes
    der= a0.to_der
    #puts der.unpack("H*")
    File.open("tmp/hellobulb2.der", "wb") { |f| f.syswrite der }
    c0 = CSRAttributes.from_der(der)
    expect(c0).to_not be_nil
  end

  def subjectAltName_ex1
    hexder="3081EE8213646177736F6E2E73616E6465"+
           "6C6D616E2E63618214646177736F6E352E"+
           "73616E64656C6D616E2E63618219677565"+
           "73742E646177736F6E2E73616E64656C6D"+
           "616E2E6361821A6775657374352E646177"+
           "736F6E2E73616E64656C6D616E2E636182"+
           "106A65642E73616E64656C6D616E2E6361"+
           "82116A6564342E73616E64656C6D616E2E"+
           "636182116A6564362E73616E64656C6D61"+
           "6E2E636182116D6573682E73616E64656C"+
           "6D616E2E63618215756E737472756E672E"+
           "73616E64656C6D616E2E63618216756E73"+
           "7472756E67362E73616E64656C6D616E2E"+
           "636182107777772E73616E64656C6D616E"+
           "2E6361"
    binder=[hexder].pack("H*")
    binder
  end
  it "should decode a sequence of subjectAltName" do
    decoded=OpenSSL::ASN1.decode(subjectAltName_ex1)
    expect(decoded.value[0].value).to eq("dawson.sandelman.ca")
    expect(decoded.value[0].tag).to eq(2)
    expect(decoded.value[1].value).to eq("dawson5.sandelman.ca")
    expect(decoded.value[1].tag).to eq(2)
    expect(decoded.value[2].value).to eq("guest.dawson.sandelman.ca")
    expect(decoded.value[2].tag).to eq(2)
    expect(decoded.value.length).to eq(11)
  end

end

