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

  describe "v6 splitting" do
    it "should split into 4-pieces" do
      v6 = ACPAddress.new("fd2c:f24d:ba5f:ab0::/60")
      (a,b,c,d) = v6.split(4)
      expect(a.to_s).to eq("fd2c:f24d:ba5f:ab0::")
      expect(a.prefix).to eq(62)

      expect(b.to_s).to eq("fd2c:f24d:ba5f:ab4::")
      expect(b.prefix).to eq(62)

      expect(c.to_s).to eq("fd2c:f24d:ba5f:ab8::")
      expect(c.prefix).to eq(62)

      expect(d.to_s).to eq("fd2c:f24d:ba5f:abc::")
      expect(d.prefix).to eq(62)
    end
    it "should split into 3-pieces" do
      v6 = ACPAddress.new("fd2c:f24d:ba5f:ab0::/60")
      (a,b,c) = v6.split(3)
      expect(a.to_s).to eq("fd2c:f24d:ba5f:ab0::")
      expect(a.prefix).to eq(62)

      expect(b.to_s).to eq("fd2c:f24d:ba5f:ab4::")
      expect(b.prefix).to eq(62)

      expect(c.to_s).to eq("fd2c:f24d:ba5f:ab8::")
      expect(c.prefix).to eq(62)
    end

    it "should split into 32-pieces" do
      v6 = ACPAddress.new("fd2c:f24d:ba5f:ab0::/60")
      pieces = v6.split(32)

      a = pieces[0]
      expect(a.to_s).to eq("fd2c:f24d:ba5f:ab0::")
      expect(a.prefix).to eq(65)

      b = pieces[1]
      expect(b.to_s).to eq("fd2c:f24d:ba5f:ab0:8000::")
      expect(b.prefix).to eq(65)

      c = pieces[16]
      expect(c.to_s).to eq("fd2c:f24d:ba5f:ab8::")
      expect(c.prefix).to eq(65)

      d = pieces[31]
      expect(d.to_s).to eq("fd2c:f24d:ba5f:abf:8000::")
      expect(d.prefix).to eq(65)
    end
  end

  describe "v6 ACP allocation" do
    it "should increment acp_pool" do
      schemeinfo = ACPAddress.acp_generate("hello")
      pool = schemeinfo.registrar("abcd1234abc")

      expect(pool.to_s).to eq("fd2c:f24d:ba5f:abc:d123:4abc::")

      newaddr = pool.asa_address
      pool    = pool.next_asa_node
      expect(newaddr.to_s).to   eq("fd2c:f24d:ba5f:abc:d123:4abc::")
      expect(newaddr.prefix).to eq(120)

      expect(pool.to_s).to      eq("fd2c:f24d:ba5f:abc:d123:4abc:0:100")
      expect(pool.prefix).to    eq(128)

      newaddr = pool.asa_address
      pool    = pool.next_asa_node
      expect(newaddr.to_s).to   eq("fd2c:f24d:ba5f:abc:d123:4abc:0:100")
      expect(newaddr.prefix).to eq(120)

      expect(pool.to_s).to      eq("fd2c:f24d:ba5f:abc:d123:4abc:0:200")
      expect(pool.prefix).to    eq(128)

    end
  end

  describe "link-local address" do
    it "from EUI64" do
      a1 = ACPAddress.iid_from_eui64("0123456789abcdef")
      expect(a1.to_s).to eq("::323:4567:89ab:cdef")
    end
    it "from EUI64 with bit set" do
      a1 = ACPAddress.iid_from_eui64("1f23456789abcdef")
      expect(a1.to_s).to eq("::1f23:4567:89ab:cdef")
    end
    it "from EUI48" do
      a1 = ACPAddress.iid_from_eui48("00163e8d519b")
      expect(a1.to_s).to eq("::216:3efe:ff8d:519b")
    end
    it "from EUI" do
      a1 = ACPAddress.iid_from_eui("00163e8d519b")
      expect(a1.to_s).to eq("::216:3efe:ff8d:519b")
    end
  end

end
