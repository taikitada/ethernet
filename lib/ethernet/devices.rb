# OS-dependent gem includes.
case RUBY_PLATFORM
when /linux/
when /darwin/
  require 'system/getifaddrs'
end

# :nodoc: namespace
module Ethernet

# Information about the available Ethernet devices.
module Devices
  # An array of device names for the machine's Ethernet devices.
  def self.all
    case RUBY_PLATFORM
    when /linux/, /darwin/
      System.get_ifaddrs.keys.map(&:to_s)
    else
      raise "Unsupported platform #{RUBY_PLATFORM}"
    end
  end
  
  # The MAC address for an Ethernet device.
  #
  # Args:
  #   eth_device:: device name for the Ethernet card, e.g. 'eth0'
  def self.mac(eth_device)
    case RUBY_PLATFORM
    when /linux/
      # /usr/include/net/if.h, structure ifreq
      ifreq = [eth_device].pack 'a32'
      # 0x8927 is SIOCGIFHWADDR in /usr/include/bits/ioctls.h
      RawSocketFactory.socket.ioctl 0x8927, ifreq
      ifreq[18, 6]
    else
      raise "Unsupported platform #{RUBY_PLATFORM}"
    end
  end
end  # class Ethernet::Devices

end  # namespace Ethernet
