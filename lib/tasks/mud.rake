# -*- ruby -*-

namespace :fountain do

  # start a process that listens on a FIFO for telemetry about new devices
  desc "Create process that listens for telemetry about new devices in SOCK_DIR=/dir"
  task :mud_telemetry => :environment do
    MudTelemetrySocket.sock_dir = ENV['SOCK_DIR'] if ENV['SOCK_DIR']
    MudTelemetrySocket.loop
  end

end
