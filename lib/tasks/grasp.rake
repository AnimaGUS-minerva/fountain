# -*- ruby -*-

require 'socket'
require 'cbor'

namespace :fountain do
  desc "Start a GRASP server on port 7732"
  task :grasp => :environment do

    server = TCPServer.new "::", 7732 # Server bind to port 7732
    loop do
      Thread.start(server.accept) do |client|
        #while client = server.accept
        #byebug
        puts "New connection #{client}"
        gs = GraspServer.new(client, client)
        gs.process
      end
    end
  end

end

