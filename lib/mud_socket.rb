class MudSocket
  cattr_accessor :sock_name
  cattr_accessor :mudsocket

  @@sock_name = File.join(ENV['HOME'], "mud_controller_skt")

  def self.socknew
    begin
      sock = UNIXSocket.new(sock_name)
      self.new(sock, sock)
    rescue Errno::ECONNREFUSED
      return nil
    end
  end

  def self.mudsocket
    @@mudsocket ||= self.socknew
  end
  def self.add(args)
    if mudsocket
      mudsocket.cmd(:add, args)
    else
      return { :status => "failed -- no socket" }.with_indifferent_access
    end
  end
  def self.delete(args)
    if mudsocket
      mudsocket.cmd(:del, args)
    else
      return { :status => "failed -- no socket" }.with_indifferent_access
    end
  end

  def initialize(io_in, io_out = nil)
    @in = io_in
    @out= io_out
    self
  end

  def sendmsg(cmd)
    @out.write(cmd)
    @out.write("\n")
  end
  def recvmsg
    @in.gets("\n")
  end

  def cmd(cmd, args)
    opt = {}.merge! args
    opt[:action] = cmd
    sendmsg(opt.to_json)

    begin
      res = JSON::parse(recvmsg).with_indifferent_access
    rescue TypeError
      nil
    end
  end

end
