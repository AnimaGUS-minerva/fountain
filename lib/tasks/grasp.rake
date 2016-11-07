# -*- ruby -*-

require 'socket'
require 'cbor'

namespace :fountain do
  desc "Start a GRASP server on port 7732"
  task :grasp => :environment do

    server = TCPServer.new 7732 # Server bind to port 7732
    Thread.fork(server.accept) do |client|
      u = MessagePack::Unpacker.new(client)
      u.each { |obj|

      }
    end
  end

end

