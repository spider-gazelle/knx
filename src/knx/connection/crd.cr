class KNX
  # Connect Response Data
  class CRD < BinData
    endian :big

    LENGTH = 4

    field length : UInt8, value: ->{ 4 }
    field connect_type : ConnectType = ConnectType::Tunnel
    field identifier : UInt16
  end
end
