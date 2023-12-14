class KNX
  class Boolean < Datapoint
    # ameba:disable Style/QueryBoolMethods
    property value : Bool = false

    def initialize(@value : Bool)
    end

    def initialize(data : Bytes)
      from_bytes data
    end

    def from_bytes(data : Bytes)
      @value = data[0].bit(0) == 1
    end

    def to_bytes : Bytes
      bin_val = @value ? 1 : 0
      Bytes[bin_val]
    end
  end
end
