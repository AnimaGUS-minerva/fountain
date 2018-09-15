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


end
