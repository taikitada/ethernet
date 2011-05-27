# Wraps ifconfig calls useful for testing.
module IfconfigCli
  # Runs ifconfig and parses its output.
  def self.run
    case RUBY_PLATFORM
    when /win/
    else
      output = `ifconfig -a`
      info_blocks = output.split /\n(?=\w)/ 
      devices = Hash[info_blocks.map { |i|
        name = i.split(' ', 2).first
        mac = if match = /hwaddr\s([0-9a-f:]+)\s/i.match(i)
          # Linux ifconfig output.
          match[1].gsub(':', '').downcase
        elsif match = /ether\s([0-9a-f:]+)\s/i.match(i)
          # OSX ifconfig output.
          match[1].gsub(':', '').downcase
        elsif match = /\s(([0-9a-f]{2}:){5}[0-9a-f]{2})\s/i.match(i)
          # First thing that looks like a MAC address.
          match[1].gsub(':', '').downcase
        else
          nil
        end
        active = /inet\s/.match(i) ? true : false
        [name, { :mac => mac, :active => active }]
      }]
    end
    devices.delete_if { |k, v| v[:mac].nil? }
  end
  
  # The name of the first active Ethernet device.
  #
  # The return value will most likely be eth0 on Linux and en0 on OSX.
  def self.live_device
    run_result = run
    run_result.keys.sort.find { |device| run_result[device][:active] }
  end
end
