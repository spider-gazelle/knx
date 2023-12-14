require "./spec_helper"

describe KNX::TunnelRequest do
  it "should parse a tunnel request" do
    raw = Bytes[0x06, 0x10, 0x04, 0x20, 0x00, 0x15, 0x04, 0x01,
      0x17, 0x00, 0x11, 0x00, 0xbc, 0xe0, 0x00, 0x00,
      0x48, 0x08, 0x01, 0x00, 0x81]
    input = IO::Memory.new(raw)

    req = input.read_bytes(KNX::TunnelRequest)
    req.header.request_type.should eq(KNX::RequestTypes::TunnellingRequest)
    req.channel_id.should eq(1)
    req.sequence.should eq(23)
    req.cemi.is_group_address.should eq(true)
    req.destination_address.should eq("9/0/8")
  end

  it "should parse a tunnel ack response" do
    raw = Bytes[0x06, 0x10, 0x04, 0x21, 0x00, 0x0a, 0x04, 0x2a, 0x17, 0x00]
    input = IO::Memory.new(raw)

    req = input.read_bytes(KNX::TunnelResponse)
    req.header.request_type.should eq(KNX::RequestTypes::TunnellingACK)
    req.channel_id.should eq(42)
    req.sequence.should eq(23)
    req.status.should eq(KNX::ConnectionError::NoError)
  end
end
