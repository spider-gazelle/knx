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
  end

  it "should parse a tunnel connection state request" do
    raw = "0610020700103d0008010a094e3bbf0b".hexbytes
    input = IO::Memory.new(raw)

    req = input.read_bytes(KNX::ConnectStateRequest)
    req.header.request_type.should eq(KNX::RequestTypes::ConnectionStateRequest)
    req.control_endpoint.ip_address.should eq Socket::IPAddress.new("10.9.78.59", 48907)
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
