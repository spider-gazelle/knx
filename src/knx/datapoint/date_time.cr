class KNX
  class DateTime < Datapoint
    property value : Time = Time.utc
    property using_ntp : Bool = true
    property daylight_savings : Bool = false
    property fault : Bool = false

    def initialize(@value : Time)
    end

    def initialize(data : Bytes)
      from_datapoint data
    end

    @[Flags]
    enum ResponseFlags
      DaylightSavings
      # Just the date component is provided
      NoTime
      NoDayOfWeek
      # Month and Day of Month fields
      NoDate
      NoYear
      NoWorkingDay
      # Is this a week day / not a holiday
      WorkingDay
      Fault
    end

    enum DayOfWeek
      None = 0
      Monday
      Tuesday
      Wednesday
      Thursday
      Friday
      Saturday
      Sunday
    end

    def from_datapoint(data : Bytes)
      now = Time.local
      flags = ResponseFlags.from_value(data[6].to_i)

      year = flags.no_year? ? now.year : (data[0].to_i + 1900)
      month = flags.no_date? ? now.month : data[1].bits(0..3).to_i
      day_of_month = flags.no_date? ? now.day : data[2].bits(0..4).to_i

      # NOTE:: We ignore this
      # day_of_week = DayOfWeek.from_value data[3].bits(5..7)

      if flags.no_time?
        hour_of_day = 0
        minute = 0
        second = 0
      else
        hour_of_day = data[3].bits(0..4).to_i
        minute = data[4].bits(0..5).to_i
        second = data[5].bits(0..5).to_i
      end
      @using_ntp = data[7].bit(7) == 1
      @daylight_savings = flags.daylight_savings?
      @fault = flags.fault?

      @value = Time.local(year, month, day_of_month, hour_of_day, minute, second)
    end

    def to_datapoint : Bytes
      year = @value.year - 1900
      month = @value.month
      day_of_month = @value.day
      hour_of_day = @value.hour
      minute = @value.minute
      second = @value.second

      flags = ResponseFlags::NoDayOfWeek
      flags |= ResponseFlags::Fault if @fault
      flags |= ResponseFlags::DaylightSavings if @daylight_savings

      Bytes[year, month, day_of_month, hour_of_day, minute, second, flags.to_i, 0x80]
    end
  end
end
