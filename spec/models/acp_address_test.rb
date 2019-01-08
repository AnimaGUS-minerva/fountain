require 'rails_helper'

RSpec.describe ACPAddress do

  it "should return a 48-bit ULA-R address" do
    ula1 = ACPAddress.acp_generate("hello").ula_r
    expect(ula1.prefix).to eq(48)
  end

  it "should generate a ULA from ACP-domain" do
    ipbase = ACPAddress.acp_generate("area51.research.acp.example.com")
    expect(ipbase.prefix).to eq(48)

    # SHA256("area51.research.acp.example.com") = 89b714f3db
    expect(ipbase.hexs[0]).to eq("fd89")
    expect(ipbase.hexs[1]).to eq("b714")
    expect(ipbase.hexs[2]).to eq("f3db")
  end

  it "should have a 50-bit base scheme" do
    schemeinfo = ACPAddress.acp_generate("hello")
    expect(schemeinfo.ula_r.to_s).to         eq("fd2c:f24d:ba5f::")
    expect(schemeinfo.asa_address.to_s).to   eq("fd2c:f24d:ba5f::")
    expect(schemeinfo.edge_address.to_s).to  eq("fd2c:f24d:ba5f::8000:0")
  end

  it "should be able to add a registrar_id" do
    schemeinfo = ACPAddress.acp_generate("hello")
    scheme2 = schemeinfo.registrar("abcd1234abc")

    expect(scheme2.ula_r.to_s).to        eq("fd2c:f24d:ba5f::")
    expect(scheme2.asa_address.to_s).to  eq("fd2c:f24d:ba5f:abc:d123:4abc::")
    expect(scheme2.edge_address.to_s).to eq("fd2c:f24d:ba5f:abc:d123:4abc:8000:0")
  end


end
