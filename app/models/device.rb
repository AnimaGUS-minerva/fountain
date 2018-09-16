class Device < ActiveRecord::Base
  belongs_to :manufacturer
  belongs_to :device_type

  before_save :validate_counts

  def self.find_or_make_by_number(idevid)
    where(idevid: idevid).take || create(idevid: idevid)
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

  # when the mud_url is set up, look for a device_type with the same mud_url, and
  # if it does not exist, device_type will create it.
  def mud_url=(x)
    self.device_type = DeviceType.find_or_create_by_mud_url(x)
    self[:mud_url] = x
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

  # is device in desired device state.
  def device_state_correct?
    case device_state
    when "enabled"
      return true if need_activation?

    when "disabled"
      return true if need_deactivation?

    when "quaranteed"
      return true if need_quaranteeing?
    end
    return false
  end

  def switch_to_state!
    case device_state
    when "enabled"
      do_activation!

    when "disabled"
      do_deactivation!

    when "quaranteed"
      do_deactivation!
      do_quaranteeing!
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

  protected
  def validate_counts
    unless self.traffic_counts
      self.traffic_counts = Hash.new([0,0]).with_indifferent_access
      self.traffic_counts["packets"] = [0,0]
      self.traffic_counts["bytes"] = [0,0]
    end
    true
  end



end
