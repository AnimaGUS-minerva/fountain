require 'mud_socket'

class Device < ActiveRecord::Base
  belongs_to :manufacturer
  belongs_to :device_type
  has_many :vouchers
  has_many :voucher_requests

  before_save :validate_counts
  before_save :validate_hash_of_keys

  class DeviceDeleted < Exception
  end
  class CSRNotverified < Exception; end
  class CSRKeyNotMatched  < Exception; end
  class CSRSerialNumberDuplicated < Exception; end

  def self.hash_of_key(key)
    pubkey = key.public_key
    return '' unless pubkey
    hash = Digest::SHA2.hexdigest(pubkey.to_der)
  end

  def self.find_or_make_by_number(number)
    find_or_create_by_mac(number)
  end

  def self.find_or_create_by_mac(mac)
    where(eui64: mac).take || create(eui64: mac)
  end

  def self.find_by_mac(mac)
    where(eui64: mac).take
  end

  def self.find_by_certificate(cert)
    # extract the public key from the certificate, create a hash of it,
    # and look that up in the index.  The certificate might not match
    # exactly, as long as the public key matches.
    hash = hash_of_key(cert)
    return nil if hash.blank?
    where(idevid_hash: hash).take || where(ldevid_hash: hash).take
  end

  def self.find_or_make_by_certificate(cert)
    dev = find_by_certificate(cert)
    unless dev
      dev = create(idevid: cert.to_pem)
      dev.locate_manufacturer_by_cert
      dev.save
    end
    dev
  end

  def idevid_cert=(x)
    @idevid_cert = x
    self.idevid = x.to_pem
  end
  def idevid_cert
    unless idevid.blank?
      @idevid_cert ||= OpenSSL::X509::Certificate.new(idevid)
    end
  end

  def ldevid_cert=(x)
    @ldevid_cert = x
    self.ldevid = x.to_pem
  end

  def ldevid_cert
    unless ldevid.blank?
      @ldevid_cert ||= OpenSSL::X509::Certificate.new(ldevid)
    end
  end

  # return a cooked (model ACP_Address) version of acp_prefix
  def acp_address
    return nil unless acp_prefix
    @acp_address ||= ACPAddress.new(acp_prefix)
  end
  def acp_address=(x)
    @acp_address = nil
    self.acp_prefix = x.to_string_uncompressed
  end

  def acp_address_allocate!(format = false)
    if acp_prefix.blank?
      self.acp_address=SystemVariable.acp_pool_allocate(format)
    end
  end

  def rfc822Name_calc
    if acp_address
      sprintf("rfc%s+%s+%s@%s",
              SystemVariable.string(:rfc_ACP) || "SELF",
              acp_address.to_hex,
              SystemVariable.acp_rsub,
              SystemVariable.acp_domain)
    else
      "unknownACP"
    end
  end

  # conversion to/from rfc822NAME as per draft-ietf-anima-autonomic-control-plane,
  # section 6.10.5.  Only the ACP Vlong Addressing Sub-Scheme is supported,
  # and the asa_address format is preferred for now.
  def rfc822Name
    @rfc822Name ||= rfc822Name_calc
  end

  # generate CSR attributes for the ACP address provided.
  def csr_attributes
    ca = CSRAttributes.new
    ca.add_attr("subjectAltName", CSRAttributes.rfc822Name(rfc822Name))
    return ca
  end

  def extension_factory
    @ef ||= OpenSSL::X509::ExtensionFactory.new
  end

  # This is for signing of LDevID for this device.
  # The optional argument is a set of CSR values to go into the certificate.
  # If none are provided, then no attributes are put into place, and the
  # public key of the IDevID will be signed.
  def create_ldevid_from_csr(csrobj)
    unless csrobj.verify(csrobj.public_key)
      raise CSRNotVerified;
    end

    # not sure if this is an appropriate check.
    # it might be that we need to check the ldevid_cert too?
    if csrobj.public_key.to_der != idevid_cert.public_key.to_der and
      (ldevid_cert and csrobj.public_key.to_der != ldevid_cert.public_key.to_der)
      raise CSRKeyNotMatched;
    end

    # walk through the attributes and make a hash of them for below.
    attributes = Hash.new
    items = csrobj.subject.to_a
    items.each { |attr|
      case attr[2]
      when 12       # UTF8STRING
        attributes[attr[0]] = attr[1]
      when 19       # PRINTABLESTRING
        attributes[attr[0]] = attr[1]
      else
        # not sure what to do with other types now.
      end
    }

    # so, not found, create a device with the same serial number.
    ldevid  = OpenSSL::X509::Certificate.new
    ldevid.version = 2
    ldevid.serial = SystemVariable.randomseq(:serialnumber)
    ldevid.issuer = FountainKeys.ca.registrarkey.issuer
    ldevid.public_key = csrobj.public_key

    # 12 is about the encoding, representing UTF8String, (I think)
    unless SystemVariable.boolvalue?(:anima_acp)
      ldevid.subject    = csrobj.subject
    else
      ldevid.subject    = OpenSSL::X509::Name.new([["emailAddress", rfc822Name, 12]])

      extension_factory.subject_certificate = ldevid
      extension_factory.issuer_certificate  = FountainKeys.ca.registrarkey

      # the OID: 1.3.6.1.4.1.46930.1 is a Private Enterprise Number OID:
      #    iso.org.dod.internet.private.enterprise . SANDELMAN=46930 . 1
      # subjectAltName=otherName:1.2.3.4;UTF8:some other identifier
      rfcName=extension_factory.create_extension("subjectAltName",
                                                 sprintf("email:%s",
                                                         rfc822Name),
                                                 false)
      ldevid.add_extension(rfcName)
    end

    ldevid.not_before = Time.now
    ldevid.not_after  = Time.gm(2999,12,31)
    ldevid.add_extension(extension_factory.create_extension("basicConstraints","CA:FALSE",false))

    ldevid.sign(FountainKeys.ca.registrarprivkey, OpenSSL::Digest::SHA256.new)
    self.ldevid = ldevid.to_pem

  end

  #alias_method :get_manufacturer, :manufacturer
  def locate_manufacturer_by_cert
    unless self.manufacturer
      self.manufacturer = Manufacturer.find_or_create_manufacturer_by(idevid_cert, nil)
      save!
    end
    return manufacturer
  end

  def increment_bytes(kind, amount)
    validate_counts
    case kind
    when :incoming
      self.traffic_counts["bytes"][0] += amount
    when :outgoing
      self.traffic_counts["bytes"][1] += amount
    end
    save!
  end

  def increment_packets(kind, amount)
    validate_counts
    case kind
    when :incoming
      self.traffic_counts["packets"][0] += amount
    when :outgoing
      self.traffic_counts["packets"][1] += amount
    end
    save!
  end

  def want_disabled!
    self.device_state = "disabled"
  end

  def deleted!
    self.deleted = true
    want_disabled!
    save!
    MudSuperJob.new.perform(id)
  end

  # when a device is trusted, then it can perform an enrollment to get
  # an LDevID.
  #  - this is true of the manufacturer has been marked as blessed.
  #  - this is true if the manufacturer is marked brski, and a voucher
  #    has been obtained.
  def trusted?
    locate_manufacturer_by_cert
    return true if manufacturer.try(:trust_admin?)
    return true if manufacturer.try(:trust_brski?) and vouchers.try(:first)
    return false
  end

  # when the mud_url is set up, look for a device_type with the same mud_url, and
  # if it does not exist, device_type will create it.
  def mud_url=(x)
    x = nil if x == "-"
    want_enabled!
    if x != self[:mud_url] and self[:mud_url]
      want_reactivation!
    end
    self[:mud_url] = x
    save!
    MudSuperJob.new.perform(id)
  end

  def empty_firewall_rules?
    firewall_rule_names.nil? || firewall_rule_names.size == 0
  end

  # a device needs activation if it is
  #   a) device_enabled
  #   b) not deleted
  #   c) has no firewall_rules listed
  #
  def need_activation?
    device_enabled? && !deleted? && empty_firewall_rules?
  end

  # a device is activated if enabled, and firewall_rules are non-empty
  def activated?
    device_enabled? and !empty_firewall_rules?
  end
  def want_enabled!
    self.device_state = "enabled"
  end
  def want_reactivation!
    self.device_state = "reactivation"
  end

  # a device needs de-activation if it is
  #   a) device_enabled == false
  #   b) not deleted
  #   c) has firewall_rules listed
  #   d) has not been quaranteed
  #
  def need_deactivation?
    !device_enabled? && !quaranteed? && !deleted? && !empty_firewall_rules?
  end

  # a device needs quanteeing if it is
  #   a) device_enabled == true
  #   b) not deleted
  #   c) has been marked quaranteed
  #
  def need_quaranteeing?
    device_enabled? && !deleted? && quaranteed?
  end

  # return true if the device is in desired device state.
  def device_state_correct?
    case device_state
    when "enabled"
      return true if need_activation?

    when "disabled"
      return true if need_deactivation?

    when "reactivation"
      return false

    when "quaranteed"
      return true if need_quaranteeing?
    end
    return false
  end

  def switch_to_state!
    case device_state
    when "enabled"
      do_activation!

    when "reactivation"
      do_deactivation!
      do_activation!
      want_enabled!

    when "disabled"
      do_deactivation!

    when "quaranteed"
      do_deactivation!
      do_quaranteeing!
    when nil
      byebug
    end
    return false
  end

  # return [FILE, publicname]
  #   - the FILE with the tmpfile open,
  #   - the publicname is the public name
  #
  # visible path is in: $MUD_TMPDIR_PUBLIC
  # path to write to:   $MUD_TMPDIR
  #
  # probably should accept an optional block.
  def mud_tmp_file_name
    # make safe file by device ID
    basename = sprintf("%05d.json", self.id)

    # make the directory, just in case
    FileUtils::mkdir_p($MUD_TMPDIR);

    file = File.open(File.join($MUD_TMPDIR, basename), "w")
    pubname = File.join($MUD_TMPDIR_PUBLIC, basename)
    return file, pubname
  end

  # writes the JSON associated with the MUD file out, returns
  # the temporary file name
  def mud_file
    file, pubname = mud_tmp_file_name
    file.write device_type.validated_mud_json.to_json
    file.close

    pubname
  end

  def do_activation!
    self.device_type = DeviceType.find_or_create_by_mud_url(mud_url)
    unless self.device_type
      return false
    end

    if self.device_type.valid?
      results = MudSocket.add(:mac_addr  => eui64,
                              :file_path => mud_file)

      if results and results["status"]=="ok"
        self.firewall_rule_names = results["rules"]
        self.failure_details = results
      else
        self.failure_details = results || { "status" => "unknown error" }
      end
    else
      self.failure_details = { "status" => device_type.failure_details }
    end
    save!
  end

  def do_deactivation!
    if firewall_rule_names and firewall_rule_names.try(:size) > 0
      MudSocket.delete(:mac_addr  => eui64,
                       :rules => firewall_rule_names)
    end
  end

  def idevid=(x)
    self[:idevid] = x
    calculate_idevid_hash
  end

  def ldevid=(x)
    self[:ldevid] = x
    calculate_ldevid_hash
  end

  protected
  def validate_counts
    unless self.traffic_counts
      self.traffic_counts = Hash.new([0,0]).with_indifferent_access
      self.traffic_counts["packets"] = [0,0]
      self.traffic_counts["bytes"] = [0,0]
    end
    true
  end

  def calculate_idevid_hash
    if idevid
      idev_cert = OpenSSL::X509::Certificate.new(idevid)
      self.idevid_hash = self.class.hash_of_key(idev_cert)
    else
      self.idevid_hash = nil
    end
  end
  def validate_idevid_hash
    if idevid and idevid_hash.blank?
      calculate_idevid_hash
    end
  end

  def calculate_ldevid_hash
    if ldevid
      ldev_cert = OpenSSL::X509::Certificate.new(ldevid)
      self.ldevid_hash = self.class.hash_of_key(ldev_cert)
    else
      self.ldevid_hash = nil
    end
  end
  def validate_ldevid_hash
    if ldevid and ldevid_hash.blank?
      calculate_ldevid_hash
    end
  end


  def validate_hash_of_keys
    unless idevid_hash
      calculate_idevid_hash
    end
    unless ldevid_hash
      calculate_ldevid_hash
    end
  end



end
