require 'mud_socket'

class MockMudTelemetrySocket < MudTelemetrySocket
  def initialize(input, output)
    @fin  = File::open(input,  "r")
    if input
      @fout = File::open(output, "w")
    end
    super(@fin, @fout)

    @@tele_socket = self
  end

  def nsock
    @fin
  end

  def recvmsg(sock)
    if sock
      sock.gets("\n")
    else
      nil
    end
  end

end

