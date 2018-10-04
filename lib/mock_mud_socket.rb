require 'mud_socket'

class MockMudSocket < MudSocket
  def initialize(input, output)
    @fout = File::open(output, "w")
    if input
      @fin  = File::open(input,  "r")
    end
    super(@fin, @fout)

    @@mudsocket = self
  end

  def sendmsg(cmd)
    super(cmd)
    @out.flush
  end

  def recvmsg
    if @in
      @in.gets("\n")
    else
      # hacky solution for development!
      "{ \"status\": \"ok\" }\n"
    end
  end

end

