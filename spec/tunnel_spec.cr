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
    req.destination_address.to_s.should eq("9/0/8")

    raw = "061004200015043d00001100b4e000000002010000".hexbytes
    input = IO::Memory.new(raw)

    req = input.read_bytes(KNX::TunnelRequest)
    req.header.request_type.should eq(KNX::RequestTypes::TunnellingRequest)
    req.length.should eq 4
    req.channel_id.should eq(61)
    req.sequence.should eq(0)

    raw = "061004200015043d01002900b4e011010002010040".hexbytes
    input = IO::Memory.new(raw)

    req = input.read_bytes(KNX::TunnelRequest)
    req.header.request_type.should eq(KNX::RequestTypes::TunnellingRequest)
    req.length.should eq 4
    req.channel_id.should eq(61)
    req.sequence.should eq(1)

    raw = "061004200015043d00002e00b4e011030002010000".hexbytes
    input = IO::Memory.new(raw)

    req = input.read_bytes(KNX::TunnelRequest)
    req.header.request_type.should eq(KNX::RequestTypes::TunnellingRequest)
    req.length.should eq 4
    req.channel_id.should eq(61)
    req.sequence.should eq(0)
  end

  it "should generate a tunnel request" do
    raw = "061004200015043d00001100b4e000000002010000".hexbytes
    input = IO::Memory.new(raw)
    ref = input.read_bytes(KNX::TunnelRequest)

    req = KNX::TunnelRequest.new(ref.channel_id, ref.cemi)
    req.to_slice.should eq raw
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

  # https://doc.qt.io/qt-5/qtknx-tunnelclient-example.html

  it "should parse a tunnel connect request" do
    raw = "06100205001a08010a094e3bbf0b08010a094e3bbf0b04040200".hexbytes
    input = IO::Memory.new(raw)

    req = input.read_bytes(KNX::ConnectRequest)
    req.header.request_type.should eq(KNX::RequestTypes::ConnectRequest)
    req.control_endpoint.ip_address.should eq Socket::IPAddress.new("10.9.78.59", 48907)
    req.data_endpoint.ip_address.should eq Socket::IPAddress.new("10.9.78.59", 48907)
    req.cri.data_link_tunnel.should be_true
  end

  it "should parse a tunnel connect response" do
    raw = "0610020600143d0008010a094e510e5704041103".hexbytes
    input = IO::Memory.new(raw)

    req = input.read_bytes(KNX::ConnectResponse)
    req.header.request_type.should eq(KNX::RequestTypes::ConnectResponse)
    req.channel_id.should eq(61)
  end

  it "should parse a tunnel connection state request" do
    raw = "0610020700103d0008010a094e3bbf0b".hexbytes
    input = IO::Memory.new(raw)

    req = input.read_bytes(KNX::ConnectStateRequest)
    req.header.request_type.should eq(KNX::RequestTypes::ConnectionStateRequest)
    req.control_endpoint.ip_address.should eq Socket::IPAddress.new("10.9.78.59", 48907)
  end

  it "should generate a tunnel connection state request" do
    raw = "0610020700103d0008010a094e3bbf0b".hexbytes
    input = IO::Memory.new(raw)
    ref = input.read_bytes(KNX::ConnectStateRequest)

    req = KNX::ConnectStateRequest.new(ref.channel_id, Socket::IPAddress.new("10.9.78.59", 48907))
    req.to_slice.should eq raw
  end

  it "should parse a tunnel connection state response" do
    raw = "0610020800083d00".hexbytes
    input = IO::Memory.new(raw)

    req = input.read_bytes(KNX::ConnectStateResponse)
    req.header.request_type.should eq(KNX::RequestTypes::ConnectionStateResponse)
  end

  it "should parse a tunnel disconnect request" do
    raw = "0610020900103d0008010a094e3bbf0b".hexbytes
    input = IO::Memory.new(raw)

    req = input.read_bytes(KNX::DisconnectRequest)
    req.header.request_type.should eq(KNX::RequestTypes::DisconnectRequest)
    req.control_endpoint.ip_address.should eq Socket::IPAddress.new("10.9.78.59", 48907)
  end

  it "should parse a tunnel disconnect response" do
    raw = "0610020a00083d00".hexbytes
    input = IO::Memory.new(raw)

    req = input.read_bytes(KNX::DisconnectResponse)
    req.header.request_type.should eq(KNX::RequestTypes::DisconnectResponse)
  end
end
