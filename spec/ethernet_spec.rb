require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Ethernet do
  describe 'provision' do
    it 'delegates to Provisioning' do
      Ethernet::Provisioning.should_receive(:usermode_sockets).and_return(:yay)
      Ethernet.provision.should == :yay
    end
  end

  describe 'devices' do
    it 'delegates to Devices' do
      Ethernet::Devices.should_receive(:all).and_return(['yay'])
      Ethernet::Devices.should_receive(:mac).with('yay').and_return('42')
      golden = { 'yay' => '42' }
      Ethernet.devices.should == golden
    end
    
    let(:devices) { Ethernet.devices }
    
    it 'contains at least one device' do
      devices.keys.should have_at_least(1).name
    end

    it 'has a MAC for the first device' do
      devices[devices.keys.first].length.should == 6
    end
  end
  
  describe 'socket' do
    it 'delegates to FrameSocket' do
      Ethernet::FrameSocket.should_receive(:new).with('yay', 1234).
                            and_return(:yay)
      Ethernet.socket('yay', 1234).should == :yay
    end
  end

  describe 'raw_socket' do
    it 'delegates to RawSocketFactory' do
      Ethernet::RawSocketFactory.should_receive(:socket).with('yay', 1234).
                            and_return(:yay)
      Ethernet.raw_socket('yay', 1234).should == :yay
    end
  end
end
