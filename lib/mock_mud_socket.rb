require 'mud_socket'

class MockMudSocket < MudSocket
  def initialize(input, output)
    @fin  = File::open(input,  "r")
    if input
      @fout = File::open(output, "w")
    end
    super(@fin, @fout)

    @@mudsocket = self
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

