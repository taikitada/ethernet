require 'socket'

# :nodoc: namespace
module Ethernet

# Low-level socket creation functionality.
module RawSocketFactory
  # :nodoc: Linux-specific implementation
  def self.socket(eth_device, ether_type = nil)
    ether_type ||= all_ethernet_protocols
    socket = Socket.new raw_address_family, Socket::SOCK_RAW,
                        htons(ether_type)
    socket.setsockopt Socket::SOL_SOCKET, Socket::SO_BROADCAST, true
    set_socket_eth_device socket, eth_device, ether_type
    socket
  end
  
  class <<self
    # Sets the Ethernet interface and protocol type for a socket.
    def set_socket_eth_device(socket, eth_device, ether_type)
      if_number = Ethernet::Devices.interface_index eth_device
      # struct sockaddr_ll in /usr/include/linux/if_packet.h
      socket_address = [raw_address_family, htons(ether_type), if_number,
                        0xFFFF, 0, 0, ''].pack 'SSISCCa8'
      socket.bind socket_address
      socket
    end
    private :set_socket_eth_device
    
    # The protocol number for listening to all ethernet protocols.
    def all_ethernet_protocols
      3  # cat /usr/include/linux/if_ether.h | grep ETH_P_ALL
    end
    private :all_ethernet_protocols
    
    # The AF / PF number for raw sockets.
    def raw_address_family
      17  # cat /usr/include/bits/socket.h | grep PF_PACKET
    end
  end
end  # module Ethernet::RawSocketFactory

end  # namespace Ethernet

