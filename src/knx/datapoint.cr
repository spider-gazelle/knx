class KNX
  # TODO:: change to a macro where the value type is used to limit the possible types
  # infact, we can make the ID optional and guess the most appropriate type
  def self.datapoint(id, value) : Datapoint
    case id.to_s
    #when "1.001", "1.002", "1.003", "1.004", "1.005", "1.006", "1.007", "1.008", "1.009"
    #  Boolean.new(value)
    when "9.001"
      TwoByteFloatingPoint.new(value)
    else
      raise "unknown datapoint #{id}"
    end
  end

  abstract class Datapoint
    abstract def initialize(data : Bytes)
    abstract def to_datapoint : Bytes
    abstract def from_datapoint(data : Bytes)
  end
end

require "./datapoint/*"
