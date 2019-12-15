require "spec"
require "../src/knx"

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
    datagram.to_slice.should eq(Bytes[6, 16, 5, 48, 0, 17, 41, 0, 188, 224, 0, 1, 10, 0, 1, 0, 128])

    datagram = knx.action("1/2/0", true)
    datagram.to_slice.should eq(Bytes[6, 16, 5, 48, 0, 17, 41, 0, 188, 224, 0, 1, 10, 0, 1, 0, 129])
  end

  it "should generate byte action requests" do
    datagram = knx.action("1/2/0", 20)
    datagram.to_slice.should eq(Bytes[6, 16, 5, 48, 0, 17, 41, 0, 188, 224, 0, 1, 10, 0, 1, 0, 148])

    datagram = knx.action("1/2/0", 240)
    datagram.to_slice.should eq(Bytes[6, 16, 5, 48, 0, 18, 41, 0, 188, 224, 0, 1, 10, 0, 1, 0, 128, 240])
  end

  it "should generate status requests" do
    datagram = knx.status("1/2/1")
    datagram.to_slice.should eq(Bytes[6, 16, 5, 48, 0, 17, 41, 0, 188, 224, 0, 1, 10, 1, 0, 0, 0])
  end
end
