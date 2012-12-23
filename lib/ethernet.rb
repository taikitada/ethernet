# Facade methods for the library.
#
# See the inner classes for more advanced functionality.
module Ethernet
  # Hash mapping Ethernet device names to their MAC addresses.
  def self.devices
    Hash[Ethernet::Devices.all.map { |dev| [dev, Ethernet::Devices.mac(dev)] }]
  end

  # Ethernet socket that abstracts away frames.
  #
  # Args:
  #   eth_device:: device name for the Ethernet card, e.g. 'eth0'
  #   ether_type:: 2-byte Ethernet packet type number
  def self.socket(eth_device, ether_type)
    Ethernet::FrameSocket.new eth_device, ether_type
  end

  # Allow non-root users to create low-level Ethernet sockets.
  #
  # This is a security risk, because Ethernet sockets can be used to spy on all
  # traffic on the machine's network. This should not be called on production
  # machines.
  #
  # Returns true for success, false otherwise. If the call fails, it is most
  # likely because it is not run by root / Administrator.
  def self.provision
    Ethernet::Provisioning.usermode_sockets
  end

  # A socket that sends and receives raw Ethernet frames.
  #
  # Args:
  #   eth_device:: device name for the Ethernet card, e.g. 'eth0'
  #   ether_type:: only receive Ethernet frames with this protocol number
  def self.raw_socket(eth_device = nil, ether_type = nil)
    Ethernet::RawSocketFactory.socket eth_device, ether_type
  end
end

unless defined? Rubinius  # ffi is in the standard library in Rubinius
  require 'ffi'
end

require '../lib/ethernet/devices.rb'
require '../lib/ethernet/frame_socket.rb'
require '../lib/ethernet/provisioning.rb'
require '../lib/ethernet/raw_socket_factory.rb'
case Ethernet::Provisioning::OS
when /darwin/
  require '../lib/ethernet/devices_darwin.rb'
  require '../lib/ethernet/raw_socket_factory_darwin.rb'
when /linux/
  require '../lib/ethernet/devices_linux.rb'
  require '../lib/ethernet/raw_socket_factory_linux.rb'
end
