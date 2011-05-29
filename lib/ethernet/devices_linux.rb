# :nodoc: namespace
module Ethernet

# :nodoc: linux-specific implementation
module Devices
  # :nodoc: linux implementation
  def self.mac(eth_device)
    # structure ifreq in /usr/include/net/if.h
    ifreq = [eth_device].pack 'a32'
    # 0x8927 is SIOCGIFHWADDR in /usr/include/bits/ioctls.h
    ioctl_socket.ioctl 0x8927, ifreq
    ifreq[18, 6]
  end
  
  # :nodoc: linux implementation
  def self.interface_index(eth_device)
    # /usr/include/net/if.h, structure ifreq
    ifreq = [eth_device].pack 'a32'
    # 0x8933 is SIOCGIFINDEX in /usr/include/bits/ioctls.h
    ioctl_socket.ioctl 0x8933, ifreq
    ifreq[16, 4].unpack('I').first
  end

  # :nodoc: linux-specific implementation
  def self.ll_address_family
    17  # cat /usr/include/bits/socket.h | grep PF_PACKET
  end

  # :nodoc: linux-specific implementation
  def self.siocgifconf_ioctl
    # SIOCGIFCONF in /usr/include/bits/ioctls.h
    0x8912
  end

  # :nodoc: linux-specific implementation
  def self.ifconf_packspec
    # struct ifconf in /usr/include/net/if.h
    Ethernet::Provisioning::POINTER_SIZE == 8 ? 'QQ' : 'LL'
  end
  
  # :nodoc: linux-specific implementation
  def self.ifreq_size
    # struct ifreq in /usr/include/net/if.h
    Ethernet::Provisioning::POINTER_SIZE == 8 ? 40 : 32
  end
end  # class Ethernet::Devices

end  # namespace Ethernet
