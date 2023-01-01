# -*- ruby -*-

require 'socket'
require 'ipaddr'

require 'cbor'

# some constants for GRASP from RFC8990
M_FLOOD = 9
O_IPv6_LOCATOR = 103
IPPROTO_TCP = 6
IPPROTO_UDP = 17

def create_socket(multicast_addr, multicast_port, ifindex)
  # Create, bind, and return a UDP multicast socket
  #puts "Socket: #{multicast_addr}, #{multicast_port}, #{ifindex}"
  UDPSocket.new(Socket::AF_INET6).tap do | s |
    ip = IPAddr.new(multicast_addr).hton + [ifindex].pack('I')
    #puts "Socket #{s.inspect} with #{ip.inspect}"
    s.setsockopt(Socket::IPPROTO_IPV6, Socket::IPV6_JOIN_GROUP, ip)
    s.setsockopt(Socket::IPPROTO_IPV6, Socket::IPV6_MULTICAST_HOPS, [1].pack('I'))
    s.setsockopt(Socket::IPPROTO_IPV6, Socket::IPV6_MULTICAST_IF, [ifindex].pack('I'))
    s.setsockopt(:SOCKET, :REUSEADDR, true)
    s.setsockopt(:SOCKET, :REUSEPORT, true)
    s.bind("::", multicast_port)
  end
end

MULTICAST_ADDR = "ff02::13"
MULTICAST_PORT = 7017

def socket_on_if(ifn)
  puts "Setting up for #{ifn.name} #{ifn.addr.ip_address} [#{ifn.ifindex}]"
  mflooder = create_socket(MULTICAST_ADDR, MULTICAST_PORT, ifn.ifindex)
  #puts "Socket #{mflooder.inspect} is setup"
  [mflooder, ifn]
end

namespace :fountain do
  desc "Start a GRASP announcement server"
  task :graspannounce => :environment do

    dst = Addrinfo.udp("ff02::13", 7017)

    socket_list = []
    ifaddrs = Socket.getifaddrs.reject do |ifaddr|
      !ifaddr.addr&.ipv6_linklocal? || (ifaddr.flags & Socket::IFF_MULTICAST == 0)
    end

    ifaddrs.each { | ifn|
      socket_list << socket_on_if(ifn)
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
      socket_list.each { |item|
        sock,ifn = item

        puts "Sending on #{sock.inspect} [#{ifn.ifindex}]"
        begin
          sock.sendmsg mfloodcbor, 0, dst
        rescue
          puts "Failed: #{$?} "
        end
      }
      sleep 20
    end

  end

end

