class MudTelemetrySocket
  cattr_accessor :sock_name
  cattr_accessor :tele_socket
  attr_accessor :cmd_count

  @@sock_name = File.join(ENV['HOME'], "mud_telemetry.sock")

  def self.socknew
    sock = UNIXSocket.open(sock_name)
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

  def process_cmd(json)
    begin
      res = JSON::parse(json)
    rescue TypeError

      return [true, nil]
    end

    if cmd=res["cmd"]
      case cmd.downcase
      when "add"

      when "old"

      when "del"

      when "exit"
        return [true, nil]
      end
    end
    return [false, true]
  end

  def self.loop
    telemetry_socket.loop
  end

  def loop
    finished = false
    while !finished do
      @nsock = nsock

      while !finished && jsoncmd=recvmsg(@nsock)
        @cmd_count += 1
        (finished, item) = process_cmd(jsoncmd)
      end

    end
  end

end
