class KNX
  class Boolean < Datapoint
    property value : Bool = false

    def initialize(@value : Bool)
    end

    def initialize(data : Bytes)
      from_datapoint data
    end

    def from_datapoint(data : Bytes)
      @value = data[0].bit(0) == 1
    end

    def to_datapoint : Bytes
      bin_val = @value ? 1 : 0
      Bytes[bin_val]
    end
  end
end
