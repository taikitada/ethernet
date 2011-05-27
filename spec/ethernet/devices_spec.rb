require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Ethernet::Devices do
  let(:golden_devices) { IfconfigCli.run }
  let(:golden_active_devices) do
    golden_devices.keys.select { |device| golden_devices[device][:active] }
  end
  
  describe 'testing environment' do
    it 'should have at least one active ethernet device' do
      golden_active_devices.should have_at_least(1).device
    end
  end
  
  describe 'all' do
    let(:devices) { Ethernet::Devices.all }
    
    it "should find active ethernet devices" do
      golden_active_devices.each do |device|
        devices.should include(device)
      end
    end
  end
  
  let(:eth_device) { IfconfigCli.live_device }
  let(:mac) { Ethernet::Devices.mac eth_device }
  
  describe 'mac' do
    let(:golden_mac) { [golden_devices[eth_device][:mac]].pack('H*') }
    
    it 'should have 6 bytes' do
      mac.length.should == 6
    end
    
    it 'should match ifconfig output' do
      mac.should == golden_mac
    end
  end
end
