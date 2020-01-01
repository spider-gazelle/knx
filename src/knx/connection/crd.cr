class KNX
  # Connect Response Data
  class CRD < BinData
    endian :big

    LENGTH = 4

    uint8 length, value: ->{ 4 }
    enum_field UInt8, connect_type : ConnectType = ConnectType::Tunnel
    uint16 identifier
  end
end
