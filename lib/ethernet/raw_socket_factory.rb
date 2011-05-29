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
  def self.socket(eth_device, ether_type = nil)
    # This method is redefined in platform-specific implementations.
    raise "Unsupported os #{Ethernet::Provisioning.platform}"
  end

  class <<self
    # Converts a 16-bit integer from host-order to network-order.
    def htons(short_integer)
      [short_integer].pack('n').unpack('S').first
    end
    private :htons

    # Converts a 32-bit integer from host-order to network-order.
    def htonl(long_integer)
      [long_integer].pack('N').unpack('L').first
    end
    private :htonl
  end
end  # module Ethernet::RawSocketFactory

end  # namespace Ethernet
