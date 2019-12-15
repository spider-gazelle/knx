require "spec"
require "../src/knx"

describe "knx datapoint helper" do
  it "should parse encoded floating point numbers" do
    dp = KNX.datapoint("9.001", Bytes[0x8A, 0x24]).as(KNX::TwoByteFloatingPoint)
    dp.value.should eq(-30)
    dp.to_datapoint.should eq(Bytes[0x8A, 0x24])

    dp = KNX.datapoint("9.001", Bytes[0x0C, 0x7E]).as(KNX::TwoByteFloatingPoint)
    dp.value.should eq(23.0)
    dp.to_datapoint.should eq(Bytes[0x0C, 0x7E])

    dp = KNX.datapoint("9.001", 19.5).as(KNX::TwoByteFloatingPoint)
    dp.value.should eq(19.5)
    dp.to_datapoint.should eq(Bytes[0x07, 0x9E])

    dp = KNX.datapoint("9.001", Bytes[0x02, 0x44]).as(KNX::TwoByteFloatingPoint)
    dp.value.should eq(5.8)
    dp.to_datapoint.should eq(Bytes[0x02, 0x44])

    dp = KNX.datapoint("9.001", Bytes[0x85, 0x76]).as(KNX::TwoByteFloatingPoint)
    dp.value.should eq(-6.5)
    dp.to_datapoint.should eq(Bytes[0x85, 0x76])

    dp = KNX.datapoint("9.001", 36.7).as(KNX::TwoByteFloatingPoint)
    dp.value.should eq(36.7)
    dp.to_datapoint.should eq(Bytes[0x0F, 0x2B])

    dp = KNX.datapoint("9.001", Bytes[0x00, 0x00]).as(KNX::TwoByteFloatingPoint)
    dp.value.should eq(0)
    dp.to_datapoint.should eq(Bytes[0x00, 0x00])
  end
end
