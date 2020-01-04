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

  describe KNX::DpTime do
    it "should parse encoded times" do
      dt = KNX::DpTime.new(Bytes[0x4D, 0x17, 0x2A])
      date = dt.value
      date.hour.should eq(13)
      date.minute.should eq(23)
      date.second.should eq(42)
      dt.day.should eq(KNX::DayOfWeek::Tuesday)
      dt.to_datapoint.should eq(Bytes[0x4D, 0x17, 0x2A])
    end
  end

  describe KNX::Date do
    it "should parse an early date" do
      dt = KNX::Date.new(Bytes[0x1F, 0x01, 0x5A])
      date = dt.value
      date.day.should eq(31)
      date.month.should eq(1)
      date.year.should eq(1990)

      dt.to_datapoint.should eq(Bytes[0x1F, 0x01, 0x5A])
    end

    it "should parse later date" do
      dt = KNX::Date.new(Bytes[0x04, 0x01, 0x02])
      date = dt.value
      date.day.should eq(4)
      date.month.should eq(1)
      date.year.should eq(2002)

      dt.to_datapoint.should eq(Bytes[0x04, 0x01, 0x02])
    end
  end

  describe KNX::DpString do
    it "should parse strings" do
      dt = KNX::DpString.new(Bytes[0x4B, 0x4E, 0x58, 0x20, 0x69, 0x73, 0x20, 0x4F, 0x4B, 0x00, 0x00, 0x00, 0x00, 0x00])
      dt.value.should eq("KNX is OK")
      dt.to_datapoint.should eq(Bytes[0x4B, 0x4E, 0x58, 0x20, 0x69, 0x73, 0x20, 0x4F, 0x4B, 0x00])
    end

    it "should parse long strings" do
      bytes = Bytes[0x41, 0x41, 0x41, 0x41, 0x41, 0x42, 0x42, 0x42, 0x42, 0x42, 0x43, 0x43, 0x43, 0x43]
      dt = KNX::DpString.new(bytes)
      dt.value.should eq("AAAAABBBBBCCCC")
      dt.to_datapoint.should eq(bytes)
      dt.value = "AAAAABBBBBCCCCDD"
      dt.to_datapoint.should eq(bytes)
    end
  end

  describe KNX::FourByteFloat do
    it "should parse a 32bit float" do
      dt = KNX::FourByteFloat.new(Bytes[0x42, 0xEF, 0x00, 0x00])
      dt.value.should eq(119.5)
      dt.to_datapoint.should eq(Bytes[0x42, 0xEF, 0x00, 0x00])
    end

    it "should parse a different 32bit float" do
      dt = KNX::FourByteFloat.new(Bytes[0x3F, 0x71, 0xEB, 0x86])
      dt.value.should eq(0.94500005_f32)
      dt.to_datapoint.should eq(Bytes[0x3F, 0x71, 0xEB, 0x86])
      dt.value = 0.945000052452.to_f32
      dt.to_datapoint.should eq(Bytes[0x3F, 0x71, 0xEB, 0x86])
    end
  end
end
