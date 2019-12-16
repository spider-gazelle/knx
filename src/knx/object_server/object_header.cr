class KNX
  class ObjectServer
    class ConnectionHeader < BinData
      endian :big

      uint8 :header_length, default: 0x04
      uint8 :reserved1, default: 0x00
      uint8 :reserved2, default: 0x00
      uint8 :reserved3, default: 0x00
    end

    enum Filter
      AllValues     = 0
      ValidValues
      UpdatedValues
    end

    enum Error
      NoError             = 0
      DeviceInternalError
      NoItemFound
      BufferIsTooSmall
      ItemNotWriteable
      ServiceNotSupported
      BadServiceParam
      WrongDatapointId
      BadDatapointCommand
      BadDatapointLength
      MessageInconsistent
      ObjectServerBusy
    end

    class ObjectHeader < BinData
      endian :big

      uint8 :main_service, default: 0xF0
      uint8 :sub_service
      uint16 :start_item
      uint16 :item_count

      property filter : Filter?

      enum_field UInt8, _filter : Filter = Filter::ValidValues, value: ->{ filter ? filter : _filter }, onlyif: ->{ filter }
      enum_field UInt8, error : Error = Error::NoError, onlyif: ->{ item_count == 0 }

      # Requests or Statuses
      array items : Item, length: ->{ item_count }
    end
  end
end
