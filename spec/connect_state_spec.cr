require "./spec_helper"

describe KNX::ConnectStateRequest do
  it "should parse a connect state request" do
    raw = Bytes[0x06, 0x10, 0x02, 0x07, 0x00, 0x10, 0x15, 0x00,
      0x08, 0x01, 0xC0, 0xA8, 0xC8, 0x0C, 0xC3, 0xB4]
    input = IO::Memory.new(raw)

    req = input.read_bytes(KNX::ConnectStateRequest)
    req.header.request_type.should eq(KNX::RequestTypes::ConnectionStateRequest)
    req.control_endpoint.ip_address.should eq(Socket::IPAddress.new("192.168.200.12", 50100))
  end

  it "should parse a connect state response" do
    raw = Bytes[0x06, 0x10, 0x02, 0x08, 0x00, 0x08, 0x15, 0x21]
    input = IO::Memory.new(raw)

    req = input.read_bytes(KNX::ConnectStateResponse)
    req.header.request_type.should eq(KNX::RequestTypes::ConnectionStateResponse)
    req.channel_id.should eq(21)
    req.status.should eq(KNX::ConnectionError::ConnectionID)
  end
end
