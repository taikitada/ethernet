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
      socket = Socket.new raw_address_family, Socket::SOCK_RAW, 0
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
        socket_address = [raw_address_family, eth_device].pack('Ca16')
        socket.bind socket_address
        
        so_level = 0  # SOL_NDRVPROTO in /usr/include/net/ndrv.h
        so_option = 4  # NDRV_SETDMXSPEC in /usr/include/net/ndrv.h
        # struct ndrv_demux_desc in /usr/include/net/ndrv.h
        # NDRV_DEMUXTYPE_ETHERTYPE -> 4 in /usr/include/net/ndrv.h
        demux_desc = [4, 2, htons(ether_type), ""].pack('SSSa26')
        socket.setsockopt so_level, so_option, demux_desc
      else
        raise "Unsupported platform #{RUBY_PLATFORM}"
      end
      socket
    end
    private :set_socket_eth_device
    
    # The protocol number for listening to all ethernet protocols.
    def all_ethernet_protocols
      case RUBY_PLATFORM
      when /linux/, /darwin/
        3  # cat /usr/include/linux/if_ether.h | grep ETH_P_ALL
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

