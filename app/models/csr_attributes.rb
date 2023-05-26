#
# a class for dealing with CSR Attributes as defined by RFC7030 section 4.5.2
#
class CSRAttributes
  attr_accessor :attributes
  attr_accessor :rawentities

  def self.from_der(x)
    rawentities = OpenSSL::ASN1.decode(x)
    ca = new
    ca.rawentities = rawentities.value
    ca
  end

  # https://tools.ietf.org/html/rfc5280#section-4.2.1.6 defines subjectAltName:
  # SubjectAltName ::= GeneralNames
  # GeneralNames ::= SEQUENCE SIZE (1..MAX) OF GeneralName
  # GeneralName ::= CHOICE {
  #        otherName                       [0]     OtherName,   <-- this one,
  #        rfc822Name                      [1]     IA5String,
  def self.rfc822NameChoice
    1
  end

  def self.otherNameChoice
    0
  end

  def self.acpNodeNameOID
    @acpoid ||= OpenSSL::ASN1::ObjectId.new("1.3.6.1.5.5.7.8.10")
  end

  def self.rfc822Name(x)
    # a is rfc822Name CHOICE from RFC7030, and the result is a sequence of SANs
    v = OpenSSL::ASN1::UTF8String.new(x, rfc822NameChoice, :EXPLICIT, :CONTEXT_SPECIFIC)
    return OpenSSL::ASN1::Sequence.new([v])
  end

  def self.otherName(x)
    # a is otherNameName CHOICE from RFC7030, and the result is a sequence of SANs
    v = OpenSSL::ASN1::UTF8String.new(x)
    return OpenSSL::ASN1::Sequence.new([acpNodeNameOID,v], otherNameChoice, :EXPLICIT, :CONTEXT_SPECIFIC)
  end

  def initialize
    self.attributes = Hash.new
    self.rawentities = []
  end

  def to_der
    # this implements the part:
    #      CsrAttrs ::= SEQUENCE SIZE (0..MAX) OF AttrOrOID
    #
    n = OpenSSL::ASN1::Sequence.new(@rawentities)
    n.to_der
  end

  # return the sequence of subjectAltNames that have been requested
  # (usually just one item, but actually a sequence of CHOICE)
  def find_extReq
    attribute_by_oid("extReq")
  end

  # return the sequence of subjectAltNames that have been requested
  # (usually just one item, but actually a sequence of CHOICE)
  def find_subjectAltName
    extReq = find_extReq
    return nil unless extReq

    san_array = find_attr_in_list(extReq, OpenSSL::ASN1::ObjectId.new("subjectAltName"))

    if san_array.is_a? OpenSSL::ASN1::Sequence and san_array.value.length > 2
      # the value is in the third entry of the SEQ
      san_array.value[2]
    else
      nil
    end
  end
  def find_rfc822Name
    os_san_list = find_subjectAltName

    # The SAN inside the extReq is an OCTETSTRING, which needs to be der decoded in
    # order to look into it.
    san_list = OpenSSL::ASN1.decode(os_san_list.value)

    # loop through each each, looking for rfc822Name or otherNameChoice
    names = san_list.value.select { |san|
      san.value.length >= 2 &&
        san.value[0].value == CSRAttributes.acpNodeNameOID.value
    }

    return nil if(names.length < 1)
    return nil if(names[0].value.length < 2)

    # names contains an arrays of SubjectAltNames that are rfc822Names.
    # As there is a SET of possible values, the second array exists.
    # Within that group is a SEQ of GENERAL names.
    name = names[0].value[1].value
    return name
  end

  def add_oid(x)
    oid = OpenSSL::ASN1::ObjectId.new(x)
    @rawentities << oid
    oid
  end

  def make_attr_pair(x,y)
    OpenSSL::ASN1::Sequence.new([OpenSSL::ASN1::ObjectId.new(x),
                                 OpenSSL::ASN1::Set.new([y])])
  end

  def make_attr_extension(extnID, critical, extnValue)
    critvalue = OpenSSL::ASN1::Boolean.new(critical)
    extnValueDER = extnValue.to_der
    OpenSSL::ASN1::Sequence.new([OpenSSL::ASN1::ObjectId.new(extnID),
                                 critvalue,
                                 OpenSSL::ASN1::OctetString.new(extnValueDER)])
  end

  def add_attr(x, y)
    @rawentities << make_attr_pair(x,y)
  end

  # extReq/extensionRequest (1.2.840.113549.1.9.14).
  def add_attr_value(x, y)
    @rawentities << make_attr_pair("extReq", make_attr_extension(x, true, y))
  end

  def add_otherNameSAN(san)
    add_attr_value("subjectAltName", CSRAttributes.otherName(san))
  end

  def find_attr(x)
    t = find_attr_in_list(@rawentites, x)
  end

  def find_attr_in_list(attributes, x)
    thing = nil
    return nil if attributes.nil?
    attributes.each { |attr|
      if attr.is_a? OpenSSL::ASN1::Sequence
        if attr.value[0].is_a? OpenSSL::ASN1::Sequence or
          attr.value[0].is_a? OpenSSL::ASN1::Set
          attr.value.each { |attr2|
            if attr2.is_a? OpenSSL::ASN1::Sequence and
              attr2.value[0].is_a? OpenSSL::ASN1::ObjectId and
              attr2.value[0].oid == x.oid
              thing = attr2
            end
          }
        else
          if attr.value[0].is_a? OpenSSL::ASN1::ObjectId and
            attr.value[0].oid == x.oid
            thing = attr.value[1]
          end
        end
      end
    }
    return thing
  end

  def attribute_by_oid(oidthing)
    unless oidthing.is_a? OpenSSL::ASN1::ObjectId
      oidthing = OpenSSL::ASN1::ObjectId.new(oidthing)
    end
    @attributes[oidthing.oid]
  end

  # this walks through the SEQ of attributes that is the CSR attributes, and for each
  # one, puts it into a hash based upon the OID.
  def process_attributes!
    @rawentities.each { |attr|
      case
      when (attr.is_a? OpenSSL::ASN1::ObjectId)
        oid = attr.oid
        @attributes[oid] = attr.value
      when (attr.is_a? OpenSSL::ASN1::Sequence)
        oid = attr.value[0].oid
        @attributes[oid] = attr.value[1]
      else
        # not sure what to do with something else.
        return false
      end
    }
    return true
  end

end
