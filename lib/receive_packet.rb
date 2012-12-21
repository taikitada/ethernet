require './ethernet'

class Receiver_LLPacket
	include Ethernet

	def receive_LL_Packet(eth_device, ether_type)
		ether_type = [ether_type].pack('H*').unpack('n').first
		puts ether_type
		socket = Ethernet.raw_socket(eth_device, ether_type)
		puts 'made socket'
	end
end
puts 'made socket'
RLL = Receiver_LLPacket.new
RLL.receive_LL_Packet(ARGV[0], ARGV[1])