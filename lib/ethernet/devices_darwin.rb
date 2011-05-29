# :nodoc: namespace
module Ethernet

# :nodoc: darwin-specific implementation
module Devices
  # :nodoc: darwin implementation
  def self.ll_address_family
    18  # cat /usr/include/sys/socket.h | grep AF_PACKET
  end

  # :nodoc: darwin implementation
  def self.siocgifconf_ioctl
    # SIOCGIFCONF in /usr/include/sys/sockio.h
    # _IOW in /usr/include/sys/ioccom.h
    0xc00c6924
  end
  
  # :nodoc: darwin implementation
  def self.ifconf_packspec
    # struct ifconf in /usr/include/net/if.h
    Ethernet::Provisioning::POINTER_SIZE == 8 ? 'LQ' : 'LL'
  end

  # :nodoc: darwin implementation
  def self.ifreq_size
    # struct ifreq in /usr/include/net/if.h
    32
  end
end  # class Ethernet::Devices

end  # namespace Ethernet
