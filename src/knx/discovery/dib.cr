class KNX
  enum DescriptionType : UInt8
    DeviceInformation        = 1
    SupportedServiceFamilies
    IPConfig
    IPCurrentConfig
    KNXAddresses
    ManufacturerData         = 0xFE
  end

  @[Flags]
  enum MediumType : UInt8
    Reserved
    TP1
    PL110
    Reserved2
    RF
    IP
  end

  enum FamilyType : UInt8
    Core                = 2
    DeviceManagement
    Tunnelling
    Routing
    RemoteLogging
    RemoteConfiguration
    ObjectServer
  end

  class ServiceFamily < BinData
    endian :big

    field family_type : FamilyType = FamilyType::Core
    field version : UInt8
  end

  # Device Information Block
  class DIB < BinData
    endian :big

    field medium : MediumType = MediumType::IP
    # Device status just used to indicate if in programming mode
    field device_status : UInt8
    field source : IndividualAddress = IndividualAddress.new
    field project_installation_id : UInt16
    field device_serial : Bytes, length: ->{ 6 }
    field device_multicast_address : Bytes, length: ->{ 4 }
    field device_mac_address : Bytes, length: ->{ 6 }
    field friendly_name : String, length: ->{ 30 }

    def programming_mode?
      @device_status > 0
    end

    def name
      @friendly_name.rstrip('\0')
    end

    def mac_address
      @device_mac_address.join(':', &.to_s(16).rjust(2, '0'))
    end

    def multicast_address
      @device_multicast_address.join('.', &.to_s)
    end

    def serial
      @device_serial.join(':', &.to_s(16).rjust(2, '0'))
    end
  end

  # Generic block
  class InformationBlock < BinData
    endian :big

    field length : UInt8
    field description_type : DescriptionType = DescriptionType::DeviceInformation

    field device_info : DIB = DIB.new, onlyif: ->{ description_type == DescriptionType::DeviceInformation }
    field supported_services : Array(ServiceFamily), length: ->{ (length - 2) // 2 }, onlyif: ->{ description_type == DescriptionType::SupportedServiceFamilies }

    # Ignore data for information we can't parse
    field raw_data : Bytes, length: ->{ length - 2 }, onlyif: ->{
      !{
        DescriptionType::DeviceInformation,
        DescriptionType::SupportedServiceFamilies,
      }.includes?(description_type)
    }
  end

  # Specific info blocks
  class DeviceInfo < BinData
    endian :big

    LENGTH = 54

    field length : UInt8, value: ->{ 54 }
    field description_type : DescriptionType = DescriptionType::DeviceInformation
    field info : DIB = DIB.new

    {% for func in [:name, :mac_address, :multicast_address, :serial] %}
      def {{func.id}}
        @info.{{func.id}}
      end
    {% end %}
  end

  class SupportedServices < BinData
    endian :big

    field length : UInt8, value: ->{ families.size * 2 + 2 }
    field description_type : DescriptionType = DescriptionType::SupportedServiceFamilies
    field families : Array(ServiceFamily), length: ->{ (length - 2) // 2 }
  end
end
