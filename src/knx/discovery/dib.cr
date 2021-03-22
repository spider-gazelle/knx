class KNX
  enum DescriptionType
    DeviceInformation        = 1
    SupportedServiceFamilies
    IPConfig
    IPCurrentConfig
    KNXAddresses
    ManufacturerData         = 0xFE
  end

  # Generic block
  class InformationBlock < BinData
    endian :big

    uint8 length
    enum_field UInt8, description_type : DescriptionType = DescriptionType::DeviceInformation

    custom device_info : DIB = DIB.new, onlyif: ->{ description_type == DescriptionType::DeviceInformation }
    array supported_services : ServiceFamily, length: ->{ (length - 2) // 2 }, onlyif: ->{ description_type == DescriptionType::SupportedServiceFamilies }

    # Ignore data for information we can't parse
    bytes raw_data, length: ->{ length - 2 }, onlyif: ->{
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

    uint8 length, value: ->{ 54 }
    enum_field UInt8, description_type : DescriptionType = DescriptionType::DeviceInformation
    custom info : DIB = DIB.new

    {% for func in [:name, :mac_address, :multicast_address, :serial] %}
      def {{func.id}}
        @info.{{func.id}}
      end
    {% end %}
  end

  class SupportedServices < BinData
    endian :big

    uint8 length, value: ->{ families.size * 2 + 2 }
    enum_field UInt8, description_type : DescriptionType = DescriptionType::SupportedServiceFamilies
    array families : ServiceFamily, length: ->{ (length - 2) // 2 }
  end

  @[Flags]
  enum MediumType
    Reserved
    TP1
    PL110
    Reserved2
    RF
    IP
  end

  # Device Information Block
  class DIB < BinData
    endian :big

    enum_field UInt8, medium : MediumType = MediumType::IP
    # Device status just used to indicate if in programming mode
    uint8 device_status
    custom source : IndividualAddress = IndividualAddress.new
    uint16 project_installation_id
    bytes device_serial, length: ->{ 6 }
    bytes device_multicast_address, length: ->{ 4 }
    bytes device_mac_address, length: ->{ 6 }
    string friendly_name, length: ->{ 30 }

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

  enum FamilyType
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

    enum_field UInt8, family_type : FamilyType = FamilyType::Core
    uint8 version
  end
end
