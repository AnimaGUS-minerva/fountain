# -*- ruby -*-

require 'socket'
require 'cbor'

# some constants for GRASP from RFC8990
M_FLOOD = 9
O_IPv6_LOCATOR = 103
IPPROTO_TCP = 6
IPPROTO_UDP = 17

def socket_on_if(ifn)
  puts "Sending from #{ifn.addr.to_s} with #{ifn.ifindex}"
  byebug
  #mflooder = ifn.addr.bind
  mflooder = UDPSocket.new(Socket::AF_INET6)
  mflooder.bind(ifn.addr, 0)     # let the kernel pick a port

  # should look up the interfaces that are relevant and announce things
  mflooder.setsockopt(Socket::IPPROTO_IPV6, Socket::IPV6_MULTICAST_IF, ifn.ifindex)
  mflooder
end

namespace :fountain do
  desc "Start a GRASP announcement server"
  task :graspannounce => :environment do

    sockets = []
    Socket.getifaddrs.map { |i|
      loopback = i.flags & Socket::Constants::IFF_LOOPBACK
      puts format("Got ifn: %s %08x %08x %08x", i, i.flags, Socket::Constants::IFF_LOOPBACK,loopback)
      if loopback == 0 && i.addr.try(:ipv6?)
        sockets << socket_on_if(i)
      end
    }
    loop do
      # build grasp message in CBOR that announces the Registrar's ports.
      # right now, it supports only the TCP port that it has used.
      sessionid = 1
      myhostaddress = ["fda379a6f6ee00000200000064000001"].pack('H*')
      mytcpport = 8993   # should be passed in, extracted from configuration
      brski_method = ""  # "BRSKI_JP"
      ttl = 180000       # ttl is in milliseconds, 180s => 2.5 minutes.

      flood = [M_FLOOD, sessionid, myhostaddress, ttl,
               [["AN_join_registrar", 4, 255, brski_method],
                [O_IPv6_LOCATOR,
                 myhostaddress, IPPROTO_TCP, mytcpport]]]

      mfloodcbor = flood.to_cbor

      # data, flags, dest, port
      puts "PING!"
      sockets.each { |sock|
        sock.send mfloodcbor, 0, "fe02::13", 7017
      }
      sleep 20
    end

  end

end

