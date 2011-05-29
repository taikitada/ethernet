require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Ethernet::RawSocketFactory do
  let(:eth_device) { IfconfigCli.live_device }
  let(:mac) { Ethernet::Devices.mac eth_device }
  
  describe 'socket' do
    let(:eth_type) { 0x88B7 }
    
    before { @socket = Ethernet::RawSocketFactory.socket eth_device }
    after { @socket.close }
    
    it 'should be able to receive data' do
      @socket.should respond_to(:recv)
    end
    
    it 'should output a packet' do
      packet = [mac, mac, [eth_type].pack('n'), "\r\n" * 32].join
      @socket.send packet, 0
    end

    it 'should receive some network noise' do
      @socket.recv(4096).should_not be_empty
    end
  end
end
