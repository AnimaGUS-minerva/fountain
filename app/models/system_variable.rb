class SystemVariable < ActiveRecord::Base

  @@cache = Hash.new

  def self.dump_vars
    all.each { |thing|
      puts "#{thing.variable}: #{thing.number} #{thing.value}"
    }
    true
  end

  def self.lookup(thing)
    self.find_by_variable(thing.to_s)
  end

  def self.findormake(thing)
    v = self.lookup(thing)
    if v.nil?
      v = self.new
      v.variable = thing.to_s

      if block_given?
        # initialize it.
        yield(v)
      end
    end
    if v.value.blank? and v.number.nil? and block_given?
      # initialize it.
      yield(v)
    end
    v
  end

  def self.boolvalue?(thing)
    v = self.lookup(thing)
    return false if v.nil?
    return (v.number != 0)
  end

  def self.string(thing)
    v = self.lookup(thing)
    return nil if v.nil?
    return v.value
  end

  def self.boolcache?(thing)
    @@cache[thing] ||= boolvalue?(thing)
  end

  def self.number(thing)
    v = self.lookup(thing)
    return 0 if v.nil?
    return v.number
  end

  def self.setnumber(thing, value)
    v = self.findormake(thing)
    v.number = value
    v.save
  end

  def self.setbool(thing, value)
    v = self.findormake(thing)
    v.number = (value ? 1 : 0)
    v.save
  end

  def self.setvalue(thing, value)
    v = self.findormake(thing)
    v.value = value
    v.save
  end

  def self.nextval(thing)
    v = self.findormake(thing)
    if v.number.nil?
      v.number = 1
    end
    v.nextval
  end

  def self.get_uid
    return self.nextval(:unix_id)
  end

  def self.hostname
    hostname = findormake(:hostname)
    unless hostname
      hostname = Socket.gethostname
    end
    hostname
  end

  def after_save
    @@cache.delete(self.variable)
  end

  def nextval
    n = nil
    begin
      transaction do
        n = self.number
        m = n + 1
        self.number = m
        self.save
      end
    #rescue ActiveRecord::Rollback
    #  logger.err "failed to get nextval for #{variable}"
    end
    n
  end

  def elidedvalue
    if value.blank?
      ""
    elsif value.length > 15
      value[0..7] + ".." + value[-7..-1]
    else
      value
    end
  end

    # this generates a new pseudo-random number from the things stored into
  # the given item.  Both the number and value are used.   The value is used
  # to store the cryptographic state, and the number gives which iteration
  # this is.  This object needs to initialize itself from a nextval().
  def self.randomseq(thing)

    # first find the thing.
    v = self.findormake(thing)

    # next, see if the thing has never been initialized and initialize it with
    # a random value.
    if v.value.nil?
      prng = Random.new
      v.number = 1 unless v.number
      [1..(v.number)].each {|n|
        prng.rand(2147483648)
      }
      v.value = Base64.encode64(Marshal.dump(prng))
      v.save!
    end

    prng = Marshal.load(Base64.decode64(v.value))
    v.number = prng.rand(2147483648)
    v.value = Base64.encode64(Marshal.dump(prng))
    v.save!
    v.number
  end

  # this section is about ACP address generation, as per
  # draft-ietf-anima-autonomic-control-plane, section XX
  def self.acp_rsub
    string(:acp_rsub) || ""
  end
  def self.acp_domain
    string(:acp_domain)
  end

  def self.acp_routing_domain
    string(:acp_routing_domain) ||
      if !acp_rsub.blank?
        acp_rsub + "." + acp_domain
      else
        acp_domain
      end
  end

  def self.registrar_id
    findormake(:registrar_id) { |v|
      # need 44-bits of data here.
      # the upper two bits are always 0 in this implementation.
      v.value = SecureRandom.hex(11)
    }.value
  end

  # this is a read-only version
  def self.acp_pool
    _acp_pool.freeze
  end

  # allocate a new ACP address from pool.
  # if format = false, then allocate a VLONG-ASA address,
  # if format = true,  then allocate a VLONG-ACP-edge format.
  # see draft-ietf-autonomic-control-plane, section 6.10.2
  def self.acp_pool_allocate(format = false)
    newaddress = nil
    transaction do
      if format
        newaddress      = self._acp_pool.edge_address
        self._acp_pool  = self._acp_pool.next_edge_node
      else
        newaddress      = self._acp_pool.asa_address
        self._acp_pool  = self._acp_pool.next_asa_node
      end
    end
    newaddress
  end

  def self.newdevice_prefix
    new
  end

  private
  def self._acp_pool=(x)
    n = findormake(:acp_pool)
    n.value = Base64.encode64(Marshal.dump(x))
    n.save!
    x
  end

  def self._acp_pool
    n = findormake(:acp_pool) { |v|
      ula_r = ACPAddress.acp_generate(acp_routing_domain)

      # generate 4 subzones, use the second one.
      vlongtype = ula_r.split(4)[1]

      # now add the registrar_id to it.
      vlongtype = vlongtype.registrar(registrar_id)

      # now serialize vlongtype into string, and store it.
      v.value = Base64.encode64(Marshal.dump(vlongtype))
      v.save!
    }
    a_p = Marshal.load(Base64.decode64(n.value))
    unless a_p.kind_of? ACPAddress
      raise ACPAddress::WrongACPPoolType.new("Why is it at #{a_p.class}")
    end
    a_p
  end



end
