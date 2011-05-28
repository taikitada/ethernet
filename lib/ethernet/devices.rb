require 'ffi'

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
    case RUBY_PLATFORM
    when /linux/
      # /usr/include/net/if.h, structure ifreq
      ifreq = [eth_device].pack 'a32'
      # 0x8927 is SIOCGIFHWADDR in /usr/include/bits/ioctls.h
      RawSocketFactory.socket.ioctl 0x8927, ifreq
      ifreq[18, 6]
    when /darwin/
      info[eth_device][:mac]
    else
      raise "Unsupported platform #{RUBY_PLATFORM}"
    end
  end
  
  # Hash mapping device names to information about devices.
  def self.info
    case RUBY_PLATFORM
    when /linux/, /darwin/
      case RUBY_PLATFORM
      when /linux/
        # struct ifreq in /usr/include/net/if.h
        ifreq_size = FFI::Pointer.size == 8 ? 40 : 32
        # SIOCGIFCONF in /usr/include/bits/ioctls.h
        ioctl_num = 0x8912
        # struct ifconf in /usr/include/net/if.h
        pack_spec = FFI::Pointer.size == 8 ? 'QQ' : 'LL'
      when /darwin/
        # struct ifreq in /usr/include/net/if.h
        ifreq_size = 32
        # SIOCGIFCONF in /usr/include/sys/sockio.h
        # _IOW in /usr/include/sys/ioccom.h
        ioctl_num = 0xc00c6924
        # struct ifconf in /usr/include/net/if.h
        pack_spec = FFI::Pointer.size == 8 ? 'LQ' : 'LL'
      end
      
      # array of struct ifreq in /usr/include/net/if.h
      buffer_size = ifreq_size * 128
      buffer_ptr = FFI::MemoryPointer.new :char, buffer_size, 0
      # struct ifconf in /usr/include/net/if.h
      ifconf = [buffer_size, buffer_ptr.address].pack pack_spec
      RawSocketFactory.socket.ioctl ioctl_num, ifconf
      
      output_size = ifconf.unpack('l').first
      offset = 0
      devices = {}
      while offset < output_size
        name = (buffer_ptr + offset).read_string_to_null
        devices[name] ||= {}
        # struct sockaddr
        addr_length = [(buffer_ptr + offset + 16).read_uchar,
                       ifreq_size - 16].max
        addr_family = (buffer_ptr + offset + 17).read_uchar
        if addr_family == ll_address_family
          # struct sockaddr_dl in /usr/include/net/if_dl.h
          devices[name][:index] = (buffer_ptr + offset + 18).read_ushort
          skip = (buffer_ptr + offset + 21).read_uchar
          length = (buffer_ptr + offset + 22).read_uchar
          devices[name][:mac] =
              (buffer_ptr + offset + 24 + skip).read_string(length)
        end
        
        offset += 16 + addr_length
      end
      devices
    else
      raise "Unsupported platform #{RUBY_PLATFORM}"
    end
  end

  # The link layer address number for raw sockets. 
  def self.ll_address_family
    case RUBY_PLATFORM
    when /linux/
      16  # cat /usr/include/bits/socket.h | grep PF_NETLINK
    when /darwin/
      18  # cat /usr/include/sys/socket.h | grep AF_PACKET
    else
      raise "Unsupported platform #{RUBY_PLATFORM}"
    end
  end
end  # class Ethernet::Devices

end  # namespace Ethernet
