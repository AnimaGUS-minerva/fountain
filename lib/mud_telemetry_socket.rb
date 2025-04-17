class MudTelemetrySocket
  cattr_accessor :sock_name, :sock_dir
  cattr_accessor :tele_socket
  attr_accessor :cmd_count
  attr_accessor :end_eof

  def self.sock_dir
    @@sock_dir ||= ENV['HOME']
  end

  def self.sock_name
    @@sock_name ||= File.join(sock_dir, "mud_telemetry.sock")
  end

  def self.socknew
    File.delete(sock_name) if File.exist?(sock_name)
    sock = UNIXServer.open(sock_name)
    self.new(sock, sock)
  end

  def self.telemetry_socket
    @@tele_socket ||= self.socknew
  end

  def log
    Rails.logger
  end

  def initialize(io_in, io_out = nil)
    @cmd_count = 0
    @in = io_in
    @out= io_out
    self
  end

  def sendline(cmd)
    @out.write(cmd)
    @out.write("\n")
  end

  def sendjson(hash)
    sendline(hash.to_json)
  end
  def sendstatus(stat)
    sendjson({:status => stat})
  end

  def recvmsg(sock)
    sock.gets("\n")
  end

  def nsock
    sock = @in.accept
    log.info "MUD server has new client"
    sock
  end

  def add_device(details)
    mac_addr = details[:mac_addr]
    details.delete(:mac_addr)

    dev = Device.find_or_create_by_mac(mac_addr)
    if dev.update(details)
      log.info("added device: #{dev.name}")
      dev.save!
      sendstatus("ok")
    else
      sendstatus("failed")
    end
  end

  def old_device(details)
    mac_addr = details[:mac_addr]
    details.delete(:mac_addr)

    dev = Device.find_by_mac(mac_addr)
    if !dev
      sendstatus("not found")
    elsif dev.update(details)
      log.info("old device: #{dev.name}")
      dev.do_activation!
      dev.save!
      sendstatus("ok")
    else
      sendstatus("failed")
    end
  end

  def process_cmd(json)
    begin
      log.info("processing #{json}")
      res = JSON::parse(json).with_indifferent_access
    rescue TypeError, JSON::ParserError
      log.info("error #{$!}")
      return [true, nil]
    end

    if cmd=res[:cmd]
      log.info("telemetry processing cmd: #{cmd}")

      case cmd.downcase
      when "add"
        if details = res[:details].try(:with_indifferent_access)
          add_device(details)
        else
          sendstatus("missing arguments")
        end

      when "old"
        if details = res[:details].try(:with_indifferent_access)
          old_device(details)
        else
          sendstatus("missing arguments")
        end

      when "del"

      when "exit"
        @exitnow = true
        return [true, nil]

      else
        sendstatus("unknown cmd: #{cmd.downcase}")
      end
    else
      log.info("json had no command: #{res}")
    end
    return [false, true]
  end

  def self.loop
    telemetry_socket.loop
  end

  def loop
    log.info "MUD telemetry server start"
    @exitnow = false
    while !@exitnow do
      @nsock = nsock

      jsoncmd = nil
      finished = false
      while !finished && (jsoncmd = recvmsg(@nsock))
        @cmd_count += 1
        begin
          (finished, item) = process_cmd(jsoncmd)
        rescue Errno::ENOTCONN
          # eof on write.
          finished = true
        end
      end
      log.info("#{@cmd_count}: client exited, #{finished} #{jsoncmd} on #{@nsock}")
      if @end_eof
        @exitnow = true
      end
    end
  end

end
