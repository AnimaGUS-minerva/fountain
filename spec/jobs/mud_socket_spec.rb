require 'rails_helper'

RSpec.describe MudSocket  do
  class MockMudSocket < MudSocket
    def initialize(input, output)
      @fin  = File::open(input,  "r")
      @fout = File::open(output, "w")
      super(@fin, @fout)

      @@mudsocket = self
    end
  end

  it "should open a socket to a file" do
    mms = MockMudSocket.new("spec/files/mud/toaster_load.tin",
                            "tmp/toaster_load.tout")

    expect(MudSocket.mudsocket).to eq(mms)
  end

  it "should write a command to mud socket, and get reply" do
    mms = MockMudSocket.new("spec/files/mud/toaster_load.tin",
                            "tmp/toaster_load.tout")

    result = mms.cmd(:add,
                     {
                       mac_addr: "08:00:27:f0:5b:76",
                       file_path: "spec/files/mud/toaster_mud.json"
                     })

    expect(result["status"]).to eq('ok')
    expect(result["rules"].size).to eq(4)
    expect(result["mac_addr"]).to_not be_nil
  end

end
