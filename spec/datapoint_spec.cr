require "spec"
require "../src/knx"

describe "knx datapoint helper" do
  describe KNX::TwoByteFloatingPoint do
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

    it "should parse 2 byte floating points" do
      dt = KNX::TwoByteFloatingPoint.new(Bytes[0x06, 0xa0])
      dt.value.should eq(16.96)
      dt.to_datapoint.should eq(Bytes[0x06, 0xa0])

      dt = KNX::TwoByteFloatingPoint.new(Bytes[0xF8, 0x01])
      dt.value.should eq(-670760.96)
      dt.to_datapoint.should eq(Bytes[0xF8, 0x01])
    end
  end

  describe KNX::DateTime do
    it "should parse encoded date times" do
      dt = KNX::DateTime.new(Bytes[0x75, 0x0B, 0x1C, 0x17, 0x07, 0x18, 0x00, 0x00])
      date = dt.value
      date.year.should eq(2017)
      date.month.should eq(11)
      date.day.should eq(28)
      date.hour.should eq(23)
      date.minute.should eq(7)
      date.second.should eq(24)

      dt.to_datapoint.should eq(Bytes[0x75, 0x0B, 0x1C, 0x17, 0x07, 0x18, 0x04, 0x80])
    end
  end
end
