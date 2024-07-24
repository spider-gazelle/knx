require "./spec_helper"

describe "knx protocol helper" do
  knx = KNX.new

  before_each do
    knx = KNX.new
  end

  it "should parse and generate the same data" do
    input = Bytes[6, 16, 5, 48, 0, 17, 41, 0, 188, 224, 0, 1, 10, 0, 1, 0, 128]
    output = input.clone
    datagram = knx.read(input)
    datagram.to_slice.should eq(output)

    input = Bytes[6, 16, 5, 48, 0, 17, 41, 0, 188, 224, 0, 1, 10, 0, 1, 0, 129]
    output = input.clone
    datagram = knx.read(input)
    datagram.to_slice.should eq(output)

    datagram.data.to_slice.should eq(Bytes[1])
    datagram.source_address.to_s.should eq("0.0.1")
    datagram.destination_address.to_s.should eq("1/2/0")
  end

  it "should generate single bit action requests" do
    datagram = knx.action("1/2/0", false)
    datagram.to_slice.should eq(Bytes[6, 16, 5, 48, 0, 17, 17, 0, 188, 224, 0, 0, 10, 0, 1, 0, 128])

    datagram = knx.action("1/2/0", true)
    datagram.to_slice.should eq(Bytes[6, 16, 5, 48, 0, 17, 17, 0, 188, 224, 0, 0, 10, 0, 1, 0, 129])
  end

  it "should generate byte action requests" do
    datagram = knx.action("1/2/0", 20)
    datagram.to_slice.should eq(Bytes[6, 16, 5, 48, 0, 17, 17, 0, 188, 224, 0, 0, 10, 0, 1, 0, 148])

    datagram = knx.action("1/2/0", 240)
    datagram.to_slice.should eq(Bytes[6, 16, 5, 48, 0, 18, 17, 0, 188, 224, 0, 0, 10, 0, 2, 0, 128, 240])
  end

  it "should generate status requests" do
    datagram = knx.status("1/2/1")
    datagram.to_slice.should eq(Bytes[6, 16, 5, 48, 0, 17, 17, 0, 188, 224, 0, 0, 10, 1, 1, 0, 0])
  end

  # examples from
  # https://github.com/uptimedk/knxnet_ip/blob/master/test/knxnet_ip/telegram_test.exs

  it "should encode / decode a Group Read" do
    datagram = knx.status("0/0/3", source: "1.0.3", msg_code: :data_indicator)
    cemi_raw = "2900bce010030003010000".hexbytes
    datagram.cemi.to_slice.should eq(cemi_raw)

    input = IO::Memory.new(cemi_raw)
    cemi = input.read_bytes(KNX::CEMI)
    cemi.to_slice.should eq cemi_raw
  end

  it "should encode / decode a Group Write" do
    datagram = knx.action("0/0/3", 0x1917, source: "1.1.1")
    cemi_raw = "1100bce0110100030300801917".hexbytes
    datagram.cemi.to_slice.should eq(cemi_raw)

    input = IO::Memory.new(cemi_raw)
    cemi = input.read_bytes(KNX::CEMI)
    cemi.to_slice.should eq cemi_raw
  end

  it "should encode / decode a Group Respnse" do
    # source: "1.1.4",
    # destination: "0/0/2",
    # service: :group_response,
    # value: <<0x41, 0x46, 0x8F, 0x5C>>

    cemi_raw = "2900bce01104000205004041468F5C".hexbytes
    input = IO::Memory.new(cemi_raw)
    cemi = input.read_bytes(KNX::CEMI)
    cemi.to_slice.should eq cemi_raw
  end
end
