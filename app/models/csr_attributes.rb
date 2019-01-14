#
# a class for dealing with CSR Attributes as defined by RFC7030 section 4.5.2
#
class CSRAttributes
  attr_accessor :attributes

  def self.from_der(x)
    @attributes = OpenSSL::ASN1.decode(x)
    ca = new
    ca.attributes = @attributes.value
    ca
  end

  def to_der
    n = OpenSSL::ASN1::Sequence.new
    @attributes.each { |attr|
      n.value << attr
    }
    n.to_der
  end

  def add_oid(x)
    @attributes << OpenSSL::ASN1::ObjectId.new(x)
  end

  def make_attr_pair(x,y)
    s = OpenSSL::ASN1::Sequence.new
    s.value << OpenSSL::ASN1::ObjectId.new(x)
    st = OpenSSL::ASN1::Set.new
    st << OpenSSL::ASN1::ObjectId.new(y)
    s.value << st
    return s
  end

  def add_attr(x, y)
    @attributes << make_attr_pair(x,y)
  end

  def find_attr(x)
    things = @attributes.select { |attr|
      attr.is_a? OpenSSL::ASN1::Sequence and
        attr.value[0].is_a? OpenSSL::ASN1::ObjectId and
        attr.value[0].oid == x.oid
    }
    if things.first
      t=things.first
      s = t.value[1]
      return s.value
    end
    return []
  end

end
