require 'socket'

# :nodoc: namespace
module Ethernet

# Low-level socket creation functionality.
module RawSocketFactory
  # A raw socket sends and receives raw Ethernet frames.
  #
  # Args:
  #   eth_device:: device name for the Ethernet card, e.g. 'eth0'
  #   ether_type:: only receive Ethernet frames with this protocol number
  def self.socket(eth_device = nil, ether_type = nil)
    case RUBY_PLATFORM
    when /linux/
      ether_type ||= all_ethernet_protocols
      socket = Socket.new raw_address_family, Socket::SOCK_RAW,
                          htons(ether_type)
      socket.setsockopt Socket::SOL_SOCKET, Socket::SO_BROADCAST, true
      set_socket_eth_device(socket, eth_device, ether_type) if eth_device
    when /darwin/
      ether_type ||= all_ethernet_protocols
      socket = Socket.new raw_address_family, Socket::SOCK_RAW, 0
      socket.setsockopt Socket::SOL_SOCKET, Socket::SO_BROADCAST, true
      set_socket_eth_device(socket, eth_device, ether_type) if eth_device
    else
      raise "Unsupported platform #{RUBY_PLATFORM}"
    end
    socket
  end
  
  class <<self
    # Sets the Ethernet interface and protocol type for a socket.
    def set_socket_eth_device(socket, eth_device, ether_type)
      case RUBY_PLATFORM
      when /linux/
        if_number = Ethernet::Device.interface_index eth_device
        # struct sockaddr_ll in /usr/include/linux/if_packet.h
        socket_address = [raw_address_family, htons(ether_type), if_number,
                          0xFFFF, 0, 0, ""].pack 'SSISCCa8'
        socket.bind socket_address
      when /darwin/
        # struct sockaddr_ndrv in /usr/include/net/ndrv.h
        # IFNAMSIZ -> IF_NAMESIZE defined in /usr/include/net/if.h
        socket_address = [raw_address_family, eth_device].pack('Sa16')
        socket.bind socket_address
        
        so_level = 0  # cat /usr/include/net/ndrv.h | grep SOL_NDRVPROTO
        so_option = 4  # cat /usr/include/net/ndrv.h | grep NDRV_SETDMXSPEC
        # struct ndrv_demux_desc in /usr/include/net/ndrv.h
        # cat /usr/include/net/ndrv.h | grep NDRV_DEMUXTYPE_ETHERTYPE
        demux_desc = [4, 2, htons(ether_type), ""].pack('SSSa26')
        # struct ndrv_protocol_desc in /usr/include/net/ndrv.h
        demux_desc_ptr = FFI::MemoryPointer.new :char, demux_desc.length + 1
        demux_desc_ptr.write_string demux_desc
        if FFI::Pointer.size == 8
          pack_spec = 'LLLQ'
        else
          pack_spec = 'LLLL'
        end
        ndrv_desc = [1, 2, 1, demux_desc_ptr.address].pack pack_spec
        socket.setsockopt so_level, so_option, ndrv_desc
      else
        raise "Unsupported platform #{RUBY_PLATFORM}"
      end
      socket
    end
    private :set_socket_eth_device
    
    # The protocol number for listening to all ethernet protocols.
    def all_ethernet_protocols
      case RUBY_PLATFORM
      when /linux/
        3  # cat /usr/include/linux/if_ether.h | grep ETH_P_ALL
      when /darwin/
        0x86a0  # HACK
      else
        raise "Unsupported platform #{RUBY_PLATFORM}"
      end
    end
    private :all_ethernet_protocols
    
    # The AF / PF number for raw sockets.
    def raw_address_family
      case RUBY_PLATFORM
      when /linux/
        17  # cat /usr/include/bits/socket.h | grep PF_PACKET
      when /darwin/
        27  # cat /usr/include/sys/socket.h | grep AF_NDRV
      else
        raise "Unsupported platform #{RUBY_PLATFORM}"
      end
    end
  
    # Converts a 16-bit integer from host-order to network-order.
    def htons(short_integer)
      [short_integer].pack('n').unpack('S').first
    end
    private :htons
  end
end  # module Ethernet::RawSocketFactory

end  # namespace Ethernet

