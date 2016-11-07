class GraspServer
   M_NOOP = 0
   M_DISCOVERY = 1
   M_RESPONSE = 2
   M_REQ_NEG = 3
   M_REQ_SYN = 4
   M_NEGOTIATE = 5
   M_END = 6
   M_WAIT = 7
   M_SYNCH = 8
   M_FLOOD = 9

   O_DIVERT = 100
   O_ACCEPT = 101
   O_DECLINE = 102
   O_IPv6_LOCATOR = 103
   O_IPv4_LOCATOR = 104
   O_FQDN_LOCATOR = 105
   O_URI_LOCATOR = 106

   def initialize(insock,outsock)
     @in  = insock
     @out = outsock || insock
   end

   def cbor_unpacker
     @unpacker ||= CBOR::Unpacker.new(@in)
   end

   def can_node_join(serialno, nodeinfo)
     iid = nodeinfo[0].bytes.to_a
     fmt_iid = sprintf("%02x:%02x:%02x:%02x:%02x:%02x:%02x:%02x",
                       iid[0],iid[1],iid[2],iid[3],
                       iid[4],iid[5],iid[6],iid[7])
     puts "Looking for #{fmt_iid}"
     out = [M_END, serialno, [O_ACCEPT]].to_cbor
     @out.write(out)
   end


   def m_req_neg(req)
     serialno= req[1]
     obj = req[2]
     objname = obj[0]
     objflag = obj[1]
     loopcount=obj[2]
     case objname
     when '46930:6JOIN'
       can_node_join(serialno, obj[3])
     end
   end

   def process
     cbor_unpacker.each { |req|
       msgtype = req[0]
       serialno= req[1]
       case msgtype
       when M_REQ_NEG
         m_req_neg(req)

       when M_NOOP
         nil # this message is ignored, no reply

       #when M_DISCOVERY
       #when M_RESPONSE
       #when M_REQ_SYN
       #when M_NEGOTIATE
       #when M_END
       #when M_WAIT
       #when M_SYNCH
       #when M_FLOOD
       else
         @out.write([M_NOOP, serialno].to_cbor)
       end
     }
   end
end
