require './ethernet'

class Receiver_LLPacket
	include Ethernet

	def receive_LL_Packet(eth_device, ether_type)
		socket = socket(en0, 0x0800)
		puts 'made socket'
	end
end
puts 'made socket'
#Ho = Receiver_LLPacket.new