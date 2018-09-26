require 'rails_helper'
#require 'mock_mud_telemetry_socket'

RSpec.describe MudTelemetrySocket  do

  it "should open a socket to a file" do
    mms = MockMudTelemetrySocket.new("spec/files/mud/cmdfiles.json",
                                     "tmp/cmdreplies.json")

    expect(MudTelemetrySocket.tele_socket).to eq(mms)
  end

  it "should accept canned commands and exit when told" do
    mms = MockMudTelemetrySocket.new("spec/files/mud/cmdfiles.json",
                                     "tmp/cmdreplies.json")

    MudTelemetrySocket.loop
    expect(MudTelemetrySocket.tele_socket.cmd_count).to eq(4)
  end

  it "should accept canned commands and exit at eof" do
    mms = MockMudTelemetrySocket.new("spec/files/mud/cmdeof.json",
                                     "tmp/cmdreplies.json")

    MudTelemetrySocket.loop
    expect(MudTelemetrySocket.tele_socket.cmd_count).to eq(4)
  end

end
