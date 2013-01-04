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
    bpf = bpf_pseudo_socket
    set_bpf_eth_device bpf, eth_device, ether_type
    Ethernet::RawSocketFactory::BpfSocketWrapper.new bpf
  end

  class <<self
    # Returns a BPF file descriptor that acts almost like a link-layer socket.
    #
    # BPF means Berkeley Packet Filter, and works on FreeBSD-like kernels,
    # including Darwin.
    def bpf_pseudo_socket
      3.times do
        Dir['/dev/bpf*'].sort.each do |name|
          begin
            s = File.open name, 'r+b'
            s.sync = true
            return s
          rescue Errno::EBUSY
            # Move to the next BPF device.
          end
        end
      end
      return nil
    end
    private :bpf_pseudo_socket

    # Binds a BPF file descriptor to a device and limits packet capture.
    #
    # BPF means Berkeley Packet Filter, and works on FreeBSD-like kernels,
    # including Darwin.
    #
    # This method also sets flags so that the socket behaves as much as possible
    # like a Linux PF_PACKET raw socket.
    def set_bpf_eth_device(bpf, eth_device, ether_type)
      # BIOCSETIF in /usr/include/net/bpf.h
      # _IOW in /usr/include/sys/ioccom.h
      # struct ifreq in /usr/include/net/if.h
      bpf.ioctl 0x8020426C, [eth_device].pack('a32')

      # Receive packets as soon as they're available.
      # BIOCIMMEDIATE in /usr/include/net/bpf.h
      # _IOW in /usr/include/sys/ioccom.h
      bpf.ioctl 0x80044270, [1].pack('L')

      # Don't automatically set the Ethernet header.
      # BIOCSHDRCMPLT in /usr/include/net/bpf.h
      # _IOW in /usr/include/sys/ioccom.h
      bpf.ioctl 0x80044275, [1].pack('L')

      # Don't receive the packets that we sent ourselves.
      # BIOCSSEESENT in /usr/include/net/bpf.h
      # _IOW in /usr/include/sys/ioccom.h
      bpf.ioctl 0x80044275, [0].pack('L')

      # BPF filter programming constants in /usr/include/net/bpf.h
      if ether_type
        filter = [
          # A <- packet Ethernet type
          [0x28, 0, 0, 12],  # BPF_LD + BPF_H + BPF_ABS
          # if A == ether_type jump above next instruction
          [0x15, 1, 0, ether_type],  # BPF_JMP + BPF_JEQ + BPF_K
          # drop packet (ret K = 0)
          [0x06, 0, 0, 0]  # BPF_RET + BPF_K
        ]
      else
        filter = []
      end

      ether_mac = Ethernet::Devices.mac eth_device
      filter += [
        # A <- first byte of destination MAC address
        [0x30, 0, 0, 0],  # BPF_LD + BPF_B + BPF_ABS
        # if A & 1 (multicast MAC address) jump above exact MAC match
        [0x45, 5, 0, 1],   # BPF_JMP + BPF_JSET + BPF_K

        # A <- first 4 bytes of destination MAC addres
        [0x20, 0, 0, 0],  # BPF_LD + BPF_W + BPF_ABS
        # if A != first 4 bytes of local MAC address jump to drop instruction
        [0x15, 0, 2, ether_mac.unpack('N').first],  # BPF_JMP + BPF_JEQ + BPF_K
        # A <- last 2 bytes of destination MAC address
        [0x28, 0, 0, 4],  # BPF_LD + BPF_H + BPF_ABS
        # if A == last 2 bytes of local MAC address jump above next instruction
        [0x15, 1, 0,
            ether_mac.unpack('@4n').first],  # BPF_JMP + BPF_JEQ + BPF_K
        # drop packet (ret K = 0)
        [0x06, 0, 0, 0],  # BPF_RET + BPF_K

        # A <- packet length
        [0x80, 0, 0, 0],  # BPF_LD + BPF_W + BPF_LEN
        # ret A (accept the entire packet)
        [0x16, 0, 0, 0]  # BPF_RET + BPF_A
      ]
      filter_code = filter.map { |i| i.pack('SCCL') }.join('')
      # struct bpf_program in /usr/include/net/bpf.h
      filter_code_ptr = FFI::MemoryPointer.new :char, filter_code.length + 1
      filter_code_ptr.write_string filter_code
      if Ethernet::Provisioning::POINTER_SIZE == 8
        pack_spec = 'QQ'
      else
        pack_spec = 'LL'
      end
      bpf_program = [filter.length, filter_code_ptr.address].pack pack_spec
      # BIOCSETF in /usr/include/net/bpf.h
      # _IOW in /usr/include/sys/iocom.h
      bpf.ioctl 0x80104267, bpf_program
    end
    private :set_bpf_eth_device
  end
end  # module Ethernet::RawSocketFactory

# :nodoc: namespace
module RawSocketFactory

# Wraps a BPF file descriptor into a socket-like interface.
class BpfSocketWrapper
  # Creates a wrapper for a BPF file descriptor.
  def initialize(bpf)
    @bpf = bpf
    puts @bpf
    @read_size = read_buffer_length
    puts '@read_size' ,@read_size
    @queue = []
  end

  # Implements Socket#recv.
  def recv(buffer_size)
    while @queue.empty?
      read_buffer = @bpf.sysread @read_size
      #p read_buffer.unpack("H*")
      bytes_read = read_buffer.length
      offset = 0
      while offset < bytes_read
        # struct bpf_hdr in /usr/include/net/bpf.h
        timestamp, captured_size, original_size, header_size =
            *read_buffer.unpack('QLLS')
        @queue.push read_buffer[header_size, captured_size]
        # BPF_WORDALIGN in /usr/include/net/bpf.h
        offset += (header_size + captured_size + 3) & 0xFFF4
      end
    end
    (@queue.shift).unpack("H*")
  end

  def show_queue
    puts @queue
  end
  # Implements Socket#send.
  def send(buffer, flags)
    @bpf.write buffer
  end

  # Implements Socket#close.
  def close
    @bpf.close
  end

  # The required length of the buffer passed to the read command.
  def read_buffer_length
    io_buffer = [0].pack('L')
    # BIOCGBLEN in /usr/include/net/bpf.h
    # _IOR in /usr/include/sys/ioccom.h
    @bpf.ioctl 0x40044266, io_buffer
    io_buffer.unpack('L').first
  end
  private :read_buffer_length
end  # class Ethernet::RawSocketFactory::BpfSocketWrapper

end  # namespace Ethernet::RawSocketFactory

end  # namespace Ethernet
