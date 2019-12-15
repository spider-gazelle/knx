require "spec"
require "../src/knx"

describe KNX::Address do
  it "should parse a group address" do
    group = KNX::GroupAddress.parse("1/2/6")
    group.main_group.should eq(1)
    group.middle_group.should eq(2)
    group.sub_group.should eq(6)
    group.to_s.should eq("1/2/6")

    group.to_i.should eq(2566)
    group = KNX::GroupAddress.parse(2566)
    group.to_s.should eq("1/2/6")
    group.main_group.should eq(1)
    group.middle_group.should eq(2)
    group.sub_group.should eq(6)
  end

  it "should parse a group address 2 level" do
    group = KNX::GroupAddress2Level.parse("4/6")
    group.main_group.should eq(4)
    group.sub_group.should eq(6)
    group.to_s.should eq("4/6")

    group.to_i.should eq(8198)
    group = KNX::GroupAddress2Level.parse(8198)
    group.main_group.should eq(4)
    group.sub_group.should eq(6)
    group.to_s.should eq("4/6")
  end

  it "should parse an individual address" do
    group = KNX::IndividualAddress.parse("3.4.6")
    group.area_address.should eq(3)
    group.line_address.should eq(4)
    group.device_address.should eq(6)
    group.to_s.should eq("3.4.6")

    group.to_i.should eq(13318)
    group = KNX::IndividualAddress.parse(13318)
    group.area_address.should eq(3)
    group.line_address.should eq(4)
    group.device_address.should eq(6)
    group.to_s.should eq("3.4.6")
  end
end
