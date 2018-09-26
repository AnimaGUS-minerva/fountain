class MudTelemetrySocket
  cattr_accessor :sock_name
  cattr_accessor :tele_socket
  attr_accessor :cmd_count

  @@sock_name = File.join(ENV['HOME'], "mud_telemetry.sock")

  def self.socknew
    sock = UNIXServer.open(sock_name)
    self.new(sock, sock)
  end

  def self.telemetry_socket
    @@tele_socket ||= self.socknew
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
    @in.accept
  end

  def add_device(details)
    mac_addr = details[:mac_addr]
    details.delete(:mac_addr)

    dev = Device.find_or_create_by_mac(mac_addr)
    if dev.update_attributes(details)
      sendstatus("ok")
    else
      sendstatus("failed")
    end
  end

  def process_cmd(json)
    begin
      res = JSON::parse(json).with_indifferent_access
    rescue TypeError, JSON::ParserError

      return [true, nil]
    end

    if cmd=res[:cmd]
      case cmd.downcase
      when "add"
        if details = res[:details].try(:with_indifferent_access)
          add_device(details)
        else
          sendstatus("missing arguments")
        end

      when "old"

      when "del"

      when "exit"
        @exitnow = true
        return [true, nil]

      else
        sendstatus("unknown cmd: #{cmd.downcase}")
      end
    end
    return [false, true]
  end

  def self.loop
    telemetry_socket.loop
  end

  def loop
    @exitnow = false
    while !@exitnow do
      @nsock = nsock

      while !finished && jsoncmd=recvmsg(@nsock)
        @cmd_count += 1
        (finished, item) = process_cmd(jsoncmd)
      end

    end
  end

end
