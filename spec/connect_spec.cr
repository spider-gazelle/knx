require "spec"
require "../src/knx"

describe KNX::ConnectRequest do
  it "should parse a connect request" do
    raw = Bytes[0x06, 0x10, 0x02, 0x05, 0x00, 0x1a, 0x08, 0x01,
      0xc0, 0xa8, 0x2a, 0x01, 0x84, 0x95, 0x08, 0x01,
      0xc0, 0xa8, 0x2a, 0x01, 0xcc, 0xa9, 0x04, 0x04,
      0x02, 0x00]
    input = IO::Memory.new(raw)

    header = input.read_bytes(KNX::Header)
    header.request_type.should eq(KNX::RequestTypes::ConnectRequest)

    control_endpoint = input.read_bytes(KNX::HPAI)
    control_endpoint.ip_address.should eq(Socket::IPAddress.new("192.168.42.1", 33941))

    data_endpoint = input.read_bytes(KNX::HPAI)
    data_endpoint.ip_address.should eq(Socket::IPAddress.new("192.168.42.1", 52393))

    cri = input.read_bytes(KNX::CRI)
    cri.connect_type.should eq(KNX::ConnectType::Tunnel)
    cri.data_link_tunnel.should eq(true)
  end

  it "should parse a connect request object" do
    raw = Bytes[0x06, 0x10, 0x02, 0x05, 0x00, 0x1a, 0x08, 0x01,
      0xc0, 0xa8, 0x2a, 0x01, 0x84, 0x95, 0x08, 0x01,
      0xc0, 0xa8, 0x2a, 0x01, 0xcc, 0xa9, 0x04, 0x04,
      0x02, 0x00]
    input = IO::Memory.new(raw)

    req = input.read_bytes(KNX::ConnectRequest)
    req.header.request_type.should eq(KNX::RequestTypes::ConnectRequest)
    req.control_endpoint.ip_address.should eq(Socket::IPAddress.new("192.168.42.1", 33941))
    req.data_endpoint.ip_address.should eq(Socket::IPAddress.new("192.168.42.1", 52393))
    req.cri.connect_type.should eq(KNX::ConnectType::Tunnel)
    req.cri.data_link_tunnel.should eq(true)
  end

  it "should generate a connect request" do
    raw = Bytes[0x06, 0x10, 0x02, 0x05, 0x00, 0x1a, 0x08, 0x01,
      0xc0, 0xa8, 0x2a, 0x01, 0x84, 0x95, 0x08, 0x01,
      0xc0, 0xa8, 0x2a, 0x01, 0xcc, 0xa9, 0x04, 0x04,
      0x02, 0x00]
    input = IO::Memory.new
    req = KNX::ConnectRequest.new(Socket::IPAddress.new("192.168.42.1", 33941), Socket::IPAddress.new("192.168.42.1", 52393))
    input.write_bytes(req)

    input.to_slice.should eq(raw)
  end

  it "should parse a connect response" do
    raw = Bytes[0x06, 0x10, 0x02, 0x06, 0x00, 0x14, 0x01, 0x00,
      0x08, 0x01, 0xc0, 0xa8, 0x2a, 0x0a, 0x0e, 0x57,
      0x04, 0x04, 0x11, 0xff]
    input = IO::Memory.new(raw)

    req = input.read_bytes(KNX::ConnectResponse)
    req.header.request_type.should eq(KNX::RequestTypes::ConnectResponse)
    req.control_endpoint.ip_address.should eq(Socket::IPAddress.new("192.168.42.10", 3671))
    req.error.status.should eq(KNX::ConnectionError::NoError)
    req.crd.connect_type.should eq(KNX::ConnectType::Tunnel)
    req.crd.identifier.should eq(4607)
  end
end
