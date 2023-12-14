require "./spec_helper"

describe KNX::ObjectServer do
  knx = KNX::ObjectServer.new
  before_each { knx = KNX::ObjectServer.new }

  it "should parse and generate the same data" do
    input = Bytes[6, 32, 240, 128, 0, 21, 4, 0, 0, 0, 240, 6, 0, 2, 0, 1, 0, 2, 3, 1, 1]
    output = input.clone
    datagram = knx.read(input)
    datagram.to_slice.should eq(output)

    datagram.data[0].id.should eq(2)
    datagram.data[0].value.should eq(Bytes[1])
  end

  it "should generate single bit action requests" do
    datagram = knx.action(1, false)
    datagram.to_slice.should eq(Bytes[6, 32, 240, 128, 0, 21, 4, 0, 0, 0, 240, 6, 0, 1, 0, 1, 0, 1, 3, 1, 0])

    datagram = knx.action(2, true)
    datagram.to_slice.should eq(Bytes[6, 32, 240, 128, 0, 21, 4, 0, 0, 0, 240, 6, 0, 2, 0, 1, 0, 2, 3, 1, 1])
  end

  it "should generate byte action requests" do
    datagram = knx.action(3, 20)
    datagram.to_slice.should eq(Bytes[6, 32, 240, 128, 0, 21, 4, 0, 0, 0, 240, 6, 0, 3, 0, 1, 0, 3, 3, 1, 20])

    datagram = knx.action(4, 240)
    datagram.to_slice.should eq(Bytes[6, 32, 240, 128, 0, 21, 4, 0, 0, 0, 240, 6, 0, 4, 0, 1, 0, 4, 3, 1, 240])
  end

  it "should generate status requests" do
    datagram = knx.status(3)
    datagram.to_slice.should eq(Bytes[6, 32, 240, 128, 0, 17, 4, 0, 0, 0, 240, 5, 0, 3, 0, 1, 1])
  end
end
