require 'rails_helper'

RSpec.describe SystemVariable, type: :model do
  fixtures :all

  it "should have a fixture bar with value 34" do
    l = system_variables(:one)
    expect(l).to_not be_nil
    expect(l.variable).to eq("bar")
    expect(l.value).to    eq(34.to_s)
  end

  it "should look up name by symbol" do
    l = SystemVariable.lookup(:bar)
    expect(l).to_not be_nil
    expect(l.value).to    eq(34.to_s)
  end

  it "should make a variable if it does not already exist" do
    l = SystemVariable.findormake(:niceone)
    expect(l).to_not be_nil
    expect(l.value).to    be nil
  end

  it "should generate a sequence of random numbers" do
    l = SystemVariable.nextval(:counter)
    expect(l).to eq(1)

    l = SystemVariable.randomseq(:counter)
    expect(l).to_not eq 0
    #puts "l: #{l}"
    l = SystemVariable.randomseq(:counter)
    expect(l).to_not eq 0
    #puts "l: #{l}"
    l = SystemVariable.randomseq(:counter)
    expect(l).to_not eq 0
    #puts "l: #{l}"
  end

  describe "CSR attributes generation" do
    it "should allocate a prefix for a new device" do
      prefix = SystemVariable.newdevice_prefix

      expect(prefix).to_not be_nil
      expect(prefix.prefix).to eq(96)
    end
    it "should have a 50-bit base scheme" do
      schemeinfo = SystemVariable.acp_vlong
      expect(schemeinfo.ula_r).to         eq("")
      expect(schemeinfo.acp_addr_type).to eq("123456")
    end

    it "should have an acp-domain" do
      expect(SystemVariable.lookup(:acp_domain)).to eq("acp.example.com")
    end

    it "should generate a URL from ACP-domain" do
      ipbase = SystemVariable.acp_generate("area51.research.acp.example.com")
      expect(ipbase.prefix).to eq(48)

      # SHA256("area51.research.acp.example.com") = 89b714f3db
      expect(ipbase.hexs[0]).to eq("fd89")
      expect(ipbase.hexs[1]).to eq("b714")
      expect(ipbase.hexs[2]).to eq("f3db")
    end

  end

end
