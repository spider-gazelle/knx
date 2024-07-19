class KNX
  # takes a stab at what you are hoping for,
  # favours accuracy over what a device might be expecting
  def self.datapoint(value : Float | String | Time | Bool) : Datapoint
    case value
    in Float
      FourByteFloat.new(value.to_f32)
    in String
      DpString.new(value)
    in Time
      DateTime.new(value)
    in Bool
      Boolean.new(value)
    end
  end

  abstract class Datapoint
    abstract def initialize(data : Bytes)
    abstract def to_bytes : Bytes
    abstract def from_bytes(data : Bytes)

    def to_slice
      to_bytes
    end
  end
end

require "./datapoint/*"
