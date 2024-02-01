class KNX
  class ObjectServer
    enum Command
      NoCommand              = 0
      SetValue
      SendValue
      SetValueAndSend
      ReadValue
      ClearTransmissionState
    end

    enum Status
      IdleOK                 = 0
      IdleError
      TransmissionInProgress
      TransmissionRequest
    end

    # Request and Response items
    class Item < BinData
      endian :big

      field id : UInt16
      field request_flags : UInt8

      # Request layout
      # bit_field do
      #  bits 4, :reserved
      #  enum_bits 4, command : Command = Command::SetValue
      # end

      def command
        Command.from_value @request_flags.bits(0..3)
      end

      def command=(value : Command)
        @request_flags = @request_flags | value.to_i
      end

      # Status layout
      # bit_field do
      #  bits 3,   :reserved
      #  bits 1,   :valid
      #  bits 1,   :update_from_bus
      #  bits 1,   :data_request
      #  enum_bits 2, status : Status = Status::IdleOK
      # end

      def status
        Status.from_value @request_flags.bits(0..1)
      end

      def transmission_status
        self.status
      end

      def status=(value : Status)
        # Clear the status bits, then set them to value
        @request_flags = (@request_flags & (~0b11)) | value.to_i
      end

      def valid?
        @request_flags.bit(4) == 1
      end

      def valid=(value : Int | Bool)
        if {1, true}.includes?(value)
          @request_flags |= 1 << 4
        else
          @request_flags &= ~(1 << 4)
        end
        value
      end

      def update_from_bus?
        @request_flags.bit(3) == 1
      end

      def update_from_bus=(value : Int | Bool)
        if {1, true}.includes?(value)
          @request_flags |= 1 << 3
        else
          @request_flags &= ~(1 << 3)
        end
        value
      end

      def data_request?
        @request_flags.bit(2) == 1
      end

      def data_request=(value : Int | Bool)
        if {1, true}.includes?(value)
          @request_flags |= 1 << 2
        else
          @request_flags &= ~(1 << 2)
        end
        value
      end

      field value_length : UInt8, value: ->{ value.size.to_u8 }
      field value : Bytes, length: ->{ value_length }
    end
  end
end
