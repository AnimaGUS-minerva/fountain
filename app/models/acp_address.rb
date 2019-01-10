class ACPAddress < IPAddress::IPv6
  class WrongACPPoolType < Exception
  end

  #
  # split a prefix into n subnets
  #
  def split(n)
    bits = Math.log2(n).ceil
    nprefix = self.prefix + bits
    bsn128 = network.to_u128
    (0..(n-1)).collect { |netnum|
      sn128 = bsn128 + (netnum << (128-nprefix))
      sn = self.class.parse_u128(sn128)
      sn.prefix = nprefix
      sn
    }
  end

  #
  # returns the initial 48-bit ULA-random generated.
  #
  def ula_r
    # make a copy
    ur = clone
    ur.prefix = 48
    ur.network
  end

  def self.acp_generate(string)
    hexbytes = Digest::SHA2.hexdigest(string)

    thing="fd" + hexbytes[0..9] + ("00" * 10)
    ip = ACPAddress::parse_hex thing
    ip.prefix = 48
    return ip
  end

  #
  # accept 11 hex digits to set up as the Registrar-ID
  #
  def registrar(x)
    # do this by parsing this into an IPv6 address, then into a u128.
    # Shift it 32 bits left, and then add it to the u128 representation
    # of this address.
    regv6 = self.class.parse_hex(x)
    n = self.class.parse_u128(to_u128 + (regv6.to_u128 << 32))
    n.prefix = (128-32)
    n
  end

  #
  # clones the current address, and then sets the prefix appropriate
  # for a VLONG format address.
  #
  def node_address
    ur = clone
    ur.prefix = (50+46+24)
    ur
  end
  #
  # returns an address with the F-bit unset.
  #
  def f_bit
    (1 << (128 - (50+46+1)))
  end

  def asa_address
    a = self.class.parse_u128(asa_address_u128)
    a.prefix=120
    a
  end

  # increment the address given by 1 in the node_address (24-bits node, 8-bit V)
  def next_asa_node
    self.class.parse_u128(asa_address_u128 + 256)
  end

  #
  # returns an address with the F-bit set.
  #
  def edge_address
    a = self.class.parse_u128(edge_address_u128)
    a.prefix = 102
    a
  end

  # increment the address given by 1 in the node_address (16-bits node, 16-bit V)
  def next_edge_node
    a = self.class.parse_u128(edge_address_u128 + 65536)
    a.prefix=102
    a
  end

    private
  def asa_address_u128
    u128 = node_address.network.to_u128
    u128 &= ~(f_bit)
    u128
  end

  def edge_address_u128
    u128 = node_address.network.to_u128
    u128 |= f_bit
    u128
  end

end
