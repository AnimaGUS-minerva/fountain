# -*- ruby -*-

namespace :fountain do

  # start a process that listens on a FIFO for telemetry about new devices
  desc "Create process that listens for telemetry about new devices"
  task :mud_telemetry => :environment do
    MudTelemetrySocket.loop
  end

end
