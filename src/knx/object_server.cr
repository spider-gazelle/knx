require "bindata"

require "./header"
require "./object_server/object_header"
require "./object_server/item"
require "./object_server/datagram"

class KNX
  class ObjectServer
    @filter : Filter
    @command : Command

    def initialize(@command = Command::SetValueAndSend, @filter = Filter::ValidValues)
    end

    # Builds an Object Server command datagram for setting an index to a value
    #
    # @param index [Integer] the object address or index as defined in the object server
    # @param data [String, Integer, Array<Integer>] the value to be set at the address
    # @return [Datagram] a bindata object representing the request that can be modified further
    def action(index, data = nil, command = @command)
      cmd = Datagram.new
      cmd.add_action(index.to_i, data: data, command: command)
      cmd.header.sub_service = 0x06_u8
      cmd.header.start_item = index.to_u16
      cmd
    end

    # Builds an Object Server request datagram for querying an index value
    def status(index, item_count = 1, filter = @filter)
      data = Datagram.new
      data.header.sub_service = 0x05_u8
      data.header.start_item = index.to_u16
      data.header.item_count = item_count.to_u16
      data.header.filter = filter
      data
    end

    # Returns a KNX Object Server datagram as an object for easy inspection
    #
    # @param data [String] a binary string containing the datagram
    # @return [Datagram] a bindata object representing the data
    def read(raw_data : Bytes)
      io = IO::Memory.new(raw_data)
      io.read_bytes(Datagram)
    end
  end
end
