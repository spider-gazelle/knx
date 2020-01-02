require "spec"
require "../src/knx"

describe KNX::DisconnectRequest do
  it "should parse a disconnect request" do
    raw = Bytes[0x06, 0x10, 0x02, 0x09, 0x00, 0x10, 0x15, 0x00,
      0x08, 0x01, 0xC0, 0xA8, 0xC8, 0x0C, 0xC3, 0xB4]
    input = IO::Memory.new(raw)

    req = input.read_bytes(KNX::DisconnectRequest)
    req.header.request_type.should eq(KNX::RequestTypes::DisconnectRequest)
    req.control_endpoint.ip_address.should eq(Socket::IPAddress.new("192.168.200.12", 50100))
    req.channel_id.should eq(21)

    KNX::DisconnectRequest.new(1, Socket::IPAddress.new("192.168.200.12", 50100)).class.should eq(KNX::DisconnectRequest)
  end

  it "should parse a disconnect response" do
    raw = Bytes[0x06, 0x10, 0x02, 0x0A, 0x00, 0x08, 0x15, 0x25]
    input = IO::Memory.new(raw)

    req = input.read_bytes(KNX::DisconnectResponse)
    req.header.request_type.should eq(KNX::RequestTypes::DisconnectResponse)
    req.channel_id.should eq(21)
    req.status.should eq(KNX::ConnectionError::NoMoreUniqueConnections)
  end
end
