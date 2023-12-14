require "./spec_helper"

describe KNX::TunnelRequest do
  it "should parse a routing request" do
    raw = Bytes[0x06, 0x10, 0x05, 0x30, 0x00, 0x12, 0x29, 0x00,
      0xbc, 0xd0, 0x12, 0x02, 0x01, 0x51, 0x02, 0x00,
      0x40, 0xf0]
    input = IO::Memory.new(raw.clone)
    req = input.read_bytes(KNX::IndicationRequest)
    req.header.request_type.should eq(KNX::RequestTypes::RoutingIndication)
    req.cemi.is_group_address.should eq(true)
    req.source_address.should eq("1.2.2")
    req.destination_address.should eq("0/1/81")

    req.cemi.data_length.should eq(2)
    req.payload.should eq(Bytes[0, 0xf0])

    output = IO::Memory.new
    output.write_bytes req
    output.to_slice.should eq(raw)
  end
end
