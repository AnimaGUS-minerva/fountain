require 'rails_helper'

require 'support/mud_toaster'
require 'support/pem_data'
require 'pathname'

RSpec.describe CSRAttributes do

  def test_der
    # from tmp/generatedCSRattr.der
    Base64.decode64("MEoGCSqGSIb3DQEJBwYFK4EEACIwLAYDVR0RAQH/BCKgIDAeBggrBgEFBQcICgwScG90YXRvQGV4"+
                    "YW1wbGUuY29tBggqhkjOPQQDAw==")
  end

  def test_potato_example
    # from tmp/generatedCSRattr.der
    Base64.decode64("MGYGCSqGSIb3DQEJBzASBgcqhkjOPQIBMQcGBSuBBAAiMDsGCSqGSIb3DQEJDjEuMCwGA1UdEQEB"+
                    "/wQioCAwHgYIKwYBBQUHCAoMEnBvdGF0b0BleGFtcGxlLmNvbQYIKoZIzj0EAwM=")
  end

  def test_rfc7030_01
    # section 4.5.2 from RFC7030.
    Base64.decode64("MEEGCSqGSIb3DQEJBzASBgcqhkjOPQIBMQcGBSuBBAAiMBYGCSqGSIb3DQEJDjEJ"+
                    "BgcrBgEBAQEWBggqhkjOPQQDAw==")
  end

  def from_file(f)
    Base64.decode64(File.read(Pathname.new("spec/files/csrattrs").join(f)))
  end

  def ecPublicKey_oid
    @ecPublicKey ||= OpenSSL::ASN1::ObjectId.new("id-ecPublicKey").oid
  end

  it "should process CSR attributes from RFC7030" do
    asn1 = OpenSSL::ASN1.decode(test_rfc7030_01)
    expect(asn1).to be_a OpenSSL::ASN1::Sequence
    expect(asn1.value.length).to eq(4)

    c1 = CSRAttributes.from_der(test_rfc7030_01)
    c1.process_attributes!
    a1 = ecPublicKey_oid
    attr1=c1.attribute_by_oid(a1)
    expect(attr1).to_not be_nil
    expect(attr1.length).to eq(1)
    expect(attr1.first.sn).to eq("secp384r1")

    attr2=c1.find_extReq
    expect(attr2.value.length).to eq(1)
    expect(attr2.first.value).to eq("1.3.6.1.1.1.1.22")
  end

  it "should process CSR attributes from LAMPS email" do
    der = File.read("spec/files/csrattr_example02.der")
    asn1 = OpenSSL::ASN1.decode(der)
    expect(asn1).to be_a OpenSSL::ASN1::Sequence
    expect(asn1.value.length).to eq(1)
  end

  it "should create a CSR attribute file with SAN potato@example.com" do
    c1 = CSRAttributes.new
    o1 = c1.add_oid("challengePassword")
    o2 = OpenSSL::ASN1::ObjectId.new("id-ecPublicKey")
    c1.add_simple_value("id-ecPublicKey", OpenSSL::ASN1::ObjectId.new("secp384r1"))
    c1.add_otherNameSAN("potato@example.com")
    o3 = c1.add_oid("ecdsa-with-SHA384")

    new_der = c1.to_der
    File.open("tmp/generatedCSRattr.der", "wb") { |f| f.syswrite new_der }
    expect(new_der).to eq(test_der)

    c0 = CSRAttributes.from_der(new_der)
    c0.process_attributes!
    expect(c0.attribute_by_oid(o1)).to_not be_nil
    expect(c0.attribute_by_oid(o2)).to_not be_nil
    expect(c0.attribute_by_oid(o3)).to_not be_nil
  end

  it "should keep last attribute, when repeated" do
    c1 = CSRAttributes.new
    o2 = OpenSSL::ASN1::ObjectId.new("id-ecPublicKey")
    c1.add_simple_value("id-ecPublicKey", OpenSSL::ASN1::ObjectId.new("secp384r1"))
    c1.add_simple_value("id-ecPublicKey", OpenSSL::ASN1::ObjectId.new("secp256k1"))

    new_der = c1.to_der

    File.open("tmp/repeated-attr-csr.der", "wb") { |f| f.syswrite new_der }

    c0 = CSRAttributes.from_der(new_der)
    c0.process_attributes!
    expect(c0.attribute_by_oid(o2)).to_not be_nil
    expect(c0.attribute_by_oid(o2).value[0].oid).to eq(OpenSSL::ASN1::ObjectId.new("secp256k1").oid)
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

  def realistic_rfc822Name
    "rfc8994+fd739fc23c3440112233445500000000+@acp.example.com"
  end

  it "should validate encoding/decoding of CSR rfc822name" do
    # this exists just to make help identify actual encoding problems
    # that are sometimes burried.
    a3 = OpenSSL::ASN1::UTF8String.new(realistic_rfc822Name, 2, :EXPLICIT, :CONTEXT_SPECIFIC)
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

  it "should create a CSR attribute with a realistic subjectAltName" do
    c1 = CSRAttributes.new
    c1.add_otherNameSAN(realistic_rfc822Name)

    der=c1.to_der
    #puts der.unpack("H*")
    File.open("tmp/realisticACP.der", "wb") { |f| f.syswrite der }
    c0 = CSRAttributes.from_der(der)
    expect(c0).to_not be_nil
    expect(der).to eq(Base64.decode64("MFUwUwYDVR0RAQH/BEmgRzBFBggrBgEFBQcICgw5cmZjU0VMRitmZDczOWZjMjNjMzQ0MDExMjIz" +
                                      "MzQ0NTUwMDAwMDAwMCtAYWNwLmV4YW1wbGUuY29t"))
  end

  it "should process CSR attributes from LAMPS email" do
    der = File.read("spec/files/csrattr_example02.der")
    c0 = CSRAttributes.from_der(der)
    expect(c0).to_not be_nil
    c0.process_attributes!
    extReq = c0.find_extReq
    expect(extReq).to_not be_nil
    san = c0.find_subjectAltName
    expect(san).to_not be_nil
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

  def rfc7030csr_example01
    @example01 ||= from_file("example01.acp.csrattr.b64")
  end

  it "should process example01 from rfc7030-csrattr" do
    c0 = CSRAttributes.from_der(rfc7030csr_example01)
    expect(c0).to_not be_nil
    name = c0.find_rfc822NameOrOtherName
    expect(name).to_not be_nil
  end

  def harkins01_example
    @harkins01 ||= from_file("harkins01.csrattr.b64")
  end

  it "should process harkins01 from rfc7030-csrattr, finding no rfc822name" do
    c0 = CSRAttributes.from_der(harkins01_example)
    expect(c0).to_not be_nil
    name = c0.find_rfc822NameOrOtherName
    expect(name).to be_nil
  end

  def harkins02_example
    @harkins02 ||= from_file("harkins02.csrattr.b64")
  end

  it "should process harkins02 from rfc7030-csrattr, finding no rfc822name" do
    c0 = CSRAttributes.from_der(harkins02_example)
    expect(c0).to_not be_nil
    name = c0.find_rfc822NameOrOtherName
    expect(name).to be_nil
  end

  def harkins03_example
    @harkins03 ||= from_file("harkins03.csrattr.b64")
  end

  it "should process harkins03 from rfc7030-csrattr, finding no rfc822name" do
    c0 = CSRAttributes.from_der(harkins03_example)
    expect(c0).to_not be_nil
    name = c0.find_rfc822NameOrOtherName
    expect(name).to be_nil
  end

  def potato01_example
    @potato01 ||= from_file("potato-example.csrattr.b64")
  end

  it "should process potato-example rfc7030-csrattr, finding no rfc822name" do
    c0 = CSRAttributes.from_der(potato01_example)
    expect(c0).to_not be_nil
    name = c0.find_rfc822NameOrOtherName
    expect(name).to be_nil
  end

  def potato01_example
    @potato01 ||= from_file("potato-example.csrattr.b64")
  end

  it "should process potato-example rfc7030-csrattr, finding no rfc822name" do
    c0 = CSRAttributes.from_der(potato01_example)
    expect(c0).to_not be_nil
    name = c0.find_rfc822NameOrOtherName
    expect(name).to be_nil
  end

  def realistic_acp_example
    @acp01 ||= from_file("realistic-acp.csrattr.b64")
  end

  it "should process realistic-acp from rfc7030-csrattr, finding an rfc822name" do
    c0 = CSRAttributes.from_der(realistic_acp_example)
    expect(c0).to_not be_nil
    name = c0.find_rfc822NameOrOtherName
    expect(name).to_not be_nil
  end


  def corey_test_csr
    Base64::decode64("MWgwZgYJKoZIhvcNAQkOMVkwVzBVBgNVHREBAf8ESzBJoEcGCCsGAQUFBwgKoDsWOXJmYzg5OTQrZmQ3" +
                     "MzlmYzIzYzM0NDAxMTIyMzM0NDU1MDAwMDAwMDArQGFjcC5leGFtcGxlLmNvbQ==")
  end

  it "should decode a sample IETF CSR attribute content" do

    pending "Corey01 example has too many levels of SEQUENCE"
    c0 = CSRAttributes.from_der(corey_test_csr)
    name = c0.find_rfc822NameOrOtherName
    reference = "0I\xA0G\x06\b+\x06\x01\x05\x05\a\b\n\xA0;\x169rfc8994+fd739fc23c3440112233445500000000+@acp.example.com"
    expect(name).to eq(reference.force_encoding("ASCII-8BIT"))
  end



end

