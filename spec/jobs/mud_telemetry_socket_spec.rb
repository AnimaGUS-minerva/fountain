require 'rails_helper'
#require 'mock_mud_telemetry_socket'

require 'support/mud_toaster'

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

    MudTelemetrySocket.telemetry_socket.end_eof = true
    MudTelemetrySocket.loop
    expect(MudTelemetrySocket.tele_socket.cmd_count).to eq(4)
  end

  it "should accept canned command to create a new device" do
    # mock out all the sockets and http requests
    @mms = MockMudSocket.new("spec/files/mud/toaster_load.tin",
                             "tmp/toaster_load.tout")
    mwave_mud

    # now take commands from the mocked telemetry socket.
    mms = MockMudTelemetrySocket.new("spec/files/mud/cmdone.json",
                                     "tmp/cmdreplies.json")

    MudTelemetrySocket.telemetry_socket.end_eof = true
    MudTelemetrySocket.loop
    devL = Device.where(:eui64 => "00:12:12:77:88:99")
    expect(devL).to exist
    dev = devL.take
    expect(dev.device_type).to be_present
    expect(dev.ipv4).to eq("192.168.19.22")
    expect(dev.ipv6).to eq("fd19:49f8:89e2::f2de:f1ff:fe80:57c1")
  end

end
