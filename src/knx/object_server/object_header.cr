require "./item"

class KNX
  class ObjectServer
    class ConnectionHeader < BinData
      endian :big

      field header_length : UInt8 = 0x04
      field reserved1 : UInt8 = 0x00
      field reserved2 : UInt8 = 0x00
      field reserved3 : UInt8 = 0x00
    end

    enum Filter : UInt8
      AllValues     = 0
      ValidValues
      UpdatedValues
    end

    enum Error : UInt8
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

      field main_service : UInt8 = 0xF0
      field sub_service : UInt8
      field start_item : UInt16
      field item_count : UInt16

      property filter : Filter?

      field _filter : Filter = Filter::ValidValues, value: ->{ filter ? filter : _filter }, onlyif: ->{ filter }
      field error : Error = Error::NoError, onlyif: ->{ item_count == 0 }

      # Requests or Statuses
      field items : Array(Item), length: ->{ item_count }
    end
  end
end
