class KNX
  class ObjectServer
    class Datagram < BinData
      custom knx_header : KNX::Header = KNX::Header.new
      custom connection : ConnectionHeader = ConnectionHeader.new
      custom header : ObjectHeader = ObjectHeader.new

      def error
        @header.error
      end

      def error_code
        @header.error.to_i
      end

      def data
        @header.items
      end

      def initialize
        super
        @knx_header.version = 0x20
        @knx_header.request_type = RequestTypes::ObjectServer
      end

      def error?
        error != Error::NoError
      end

      def to_slice
        @header.item_count = @header.items.size.to_u16 if @header.items.size > 0
        bytes = super

        # set KNX header total length
        size = @knx_header.request_length = bytes.size.to_u16
        io = IO::Memory.new(2)
        io.write_bytes size, IO::ByteFormat::BigEndian
        raw_size = io.to_slice
        bytes[4] = raw_size[0]
        bytes[5] = raw_size[1]

        bytes
      end

      def add_action(index, data = nil, command = Command::SetValue)
        req = Item.new
        req.id = index.to_u16
        req.command = command

        # data might equal false hence the nil check
        if !data.nil?
          case data
          when Bool
            req.value = data ? Bytes[1] : Bytes[0]
          when Int
            # Assume single byte
            req.value = Bytes[data]
          else
            req.value = data.to_slice
          end
        end

        @header.items << req

        self
      end
    end
  end
end
