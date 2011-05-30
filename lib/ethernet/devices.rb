# :nodoc: namespace
module Ethernet

# Information about the available Ethernet devices.
module Devices
  # Array containing device names.
  def self.all
    info.keys
  end
  
  # The MAC address for an Ethernet device.
  #
  # Args:
  #   eth_device:: device name for the Ethernet card, e.g. 'eth0'
  def self.mac(eth_device)
    info[eth_device][:mac]
  end
  
  # The interface number for an Ethernet interface.
  #
  # Args:
  #   eth_device:: device name for the Ethernet card, e.g. 'eth0'
  def self.interface_index(eth_device)
    info[eth_device][:index]
  end
  
  # Hash mapping device names to information about devices.
  def self.info
    # array of struct ifreq in /usr/include/net/if.h
    buffer_size = ifreq_size * 128
    buffer_ptr = FFI::MemoryPointer.new :uchar, buffer_size, 0
    # struct ifconf in /usr/include/net/if.h
    ifconf = [buffer_size, buffer_ptr.address].pack ifconf_packspec
    ioctl_socket.ioctl siocgifconf_ioctl, ifconf
    
    output_size = ifconf.unpack('l').first
    offset = 0
    devices = {}
    while offset < output_size
      name = (buffer_ptr + offset).read_string_to_null
      devices[name] ||= {}
      # struct sockaddr
      addr_length, addr_family = *(buffer_ptr + offset + 16).read_string(2).
                                                             unpack('CC')
      addr_length = ifreq_size - 16 if addr_length < ifreq_size - 16
      if addr_family == ll_address_family
        # struct sockaddr_dl in /usr/include/net/if_dl.h
        devices[name][:index], blah, skip, length =
            *(buffer_ptr + offset + 18).read_string(4).unpack('SCCC')
        devices[name][:mac] =
            (buffer_ptr + offset + 24 + skip).read_string(length)
      end
      
      offset += 16 + addr_length
    end
    
    if devices.all? { |k, v| v[:mac].nil? }
      # Linux only provides IP addresses in SIOCGIFCONF.
      devices.keys.each do |device|
        devices[device][:mac] ||= mac device
        devices[device][:index] ||= interface_index device
      end
    end
    devices.delete_if { |k, v| v[:mac].nil? || v[:mac].empty? }
    
    devices
  end
  
  class <<self
    # SIOCGIFCONF ioctl number.
    def siocgifconf_ioctl
      raise "Unsupported os #{Ethernet::Provisioning::OS}"
    end
    
    
    # Array#pack specification for struct ifconf.
    #
    # The specification converts a [size, pointer] array into a valid struct.
    def ifconf_packspec
      raise "Unsupported os #{Ethernet::Provisioning::OS}"
    end
    private :ifconf_packspec
    
    # Size of a struct ifreq.
    def ifreq_size
      raise "Unsupported os #{Ethernet::Provisioning::OS}"
    end
    private :ifreq_size
    
    # The link layer address number for raw sockets. 
    def ll_address_family
      raise "Unsupported os #{Ethernet::Provisioning::OS}"
    end
    private :ll_address_family
  
    # Socket that is solely used for issuing ioctls.
    def ioctl_socket
      Socket.new(Socket::AF_INET, Socket::SOCK_DGRAM, 0)
    end
    private :ioctl_socket
  end
end  # class Ethernet::Devices

end  # namespace Ethernet
