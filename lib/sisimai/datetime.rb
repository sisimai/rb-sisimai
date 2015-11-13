require "date"

module Sisimai::DateTime
  # Imported from p5-Sisimail/lib/Sisimai/DateTime.pm
  class << self
    BASE_D = 86400    # 1 day = 86400 sec
    BASE_Y = 365.2425 # 1 year = 365.2425 days
    BASE_L = 29.53059 # 1 lunar month = 29.53059 days

    CONST_P = 4 * Math.atan2(1,1) # PI, 3.1415926535
    CONST_E = Math.exp(1)         # e, Napier's constant
    TZ_OFFSET = 54000             # Max time zone offset, 54000 seconds

    @@TimeUnit = {
      'o' => ( BASE_D * BASE_Y * 4 ), # Olympiad, 4 years
      'y' => ( BASE_D * BASE_Y ),     # Year, Gregorian Calendar
      'q' => ( BASE_D * BASE_Y / 4 ), # Quarter, year/4
      'l' => ( BASE_D * BASE_L ),     # Lunar month
      'f' => ( BASE_D * 14 ),         # Fortnight, 2 weeks
      'w' => ( BASE_D * 7 ),          # Week, 604800 seconds
      'd' => BASE_D,                  # Day
      'h' => 3600,                    # Hour
      'b' => 86.4,                    # Beat, Swatch internet time: 1000b = 1d
      'm' => 60,                      # Minute,
      's' => 1,                       # Second
    }

    @@MathematicalConstant = {
      'e' => CONST_E,
      'p' => CONST_P,
      'g' => CONST_E ** CONST_P,
    }

    @@MonthName = {
      'full' => [ 
        'January', 'February', 'March', 'April', 'May', 'June', 'July', 
        'August', 'September', 'October', 'November', 'December',
      ],
      'abbr' => [ 
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ],
    }

    @@DayOfWeek = {
      'full' => [
        'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday',
      ],
      'abbr' => [ 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', ],
    }

    @@HourName = {
      'full' => [ 
        'Midnight',1,2,3,4,5,'Morning',7,8,9,10,11,'Noon',
        13,14,15,16,17,'Evening',19,20,21,22,23,
      ],
      'abbr' => [ 0..23 ],
    }

    @@TimeZoneAbbr = {
      # http://en.wikipedia.org/wiki/List_of_time_zone_abbreviations
      #'ACDT' => '+1030', # Australian Central Daylight Time  UTC+10:30
      #'ACST' => '+0930', # Australian Central Standard Time  UTC+09:30
      #'ACT'  => '+0800', # ASEAN Common Time                 UTC+08:00
      'ADT'   => '-0300', # Atlantic Daylight Time            UTC-03:00
      #'AEDT' => '+1100', # Australian Eastern Daylight Time  UTC+11:00
      #'AEST' => '+1000', # Australian Eastern Standard Time  UTC+10:00
      #'AFT'  => '+0430', # Afghanistan Time                  UTC+04:30
      'AKDT'  => '-0800', # Alaska Daylight Time              UTC-08:00
      'AKST'  => '-0900', # Alaska Standard Time              UTC-09:00
      #'AMST' => '+0500', # Armenia Summer Time               UTC+05:00
      #'AMT'  => '+0400', # Armenia Time                      UTC+04:00
      #'ART'  => '-0300', # Argentina Time                    UTC+03:00
      #'AST'  => '+0300', # Arab Standard Time (Kuwait, Riyadh)       UTC+03:00
      #'AST'  => '+0400', # Arabian Standard Time (Abu Dhabi, Muscat) UTC+04:00
      #'AST'  => '+0300', # Arabic Standard Time (Baghdad)    UTC+03:00
      'AST'   => '-0400', # Atlantic Standard Time            UTC-04:00
      #'AWDT' => '+0900', # Australian Western Daylight Time  UTC+09:00
      #'AWST' => '+0800', # Australian Western Standard Time  UTC+08:00
      #'AZOST'=> '-0100', # Azores Standard Time              UTC-01:00
      #'AZT'  => '+0400', # Azerbaijan Time                   UTC+04:00
      #'BDT'  => '+0800', # Brunei Time                       UTC+08:00
      #'BIOT' => '+0600', # British Indian Ocean Time         UTC+06:00
      #'BIT'  => '-1200', # Baker Island Time                 UTC-12:00
      #'BOT'  => '-0400', # Bolivia Time                      UTC-04:00
      #'BRT'  => '-0300', # Brasilia Time                     UTC-03:00
      #'BST'  => '+0600', # Bangladesh Standard Time          UTC+06:00
      #'BST'  => '+0100', # British Summer Time (British Standard Time from Feb 1968 to Oct 1971) UTC+01:00
      #'BTT'  => '+0600', # Bhutan Time                       UTC+06:00
      #'CAT'  => '+0200', # Central Africa Time               UTC+02:00
      #'CCT'  => '+0630', # Cocos Islands Time                UTC+06:30
      'CDT'   => '-0500', # Central Daylight Time (North America)     UTC-05:00
      #'CEDT' => '+0200', # Central European Daylight Time    UTC+02:00
      #'CEST' => '+0200', # Central European Summer Time      UTC+02:00
      #'CET'  => '+0100', # Central European Time             UTC+01:00
      #'CHAST'=> '+1245', # Chatham Standard Time             UTC+12:45
      #'CIST' => '-0800', # Clipperton Island Standard Time   UTC-08:00
      #'CKT'  => '-1000', # Cook Island Time                  UTC-10:00
      #'CLST' => '-0300', # Chile Summer Time                 UTC-03:00
      #'CLT'  => '-0400', # Chile Standard Time               UTC-04:00
      #'COST' => '-0400', # Colombia Summer Time              UTC-04:00
      #'COT'  => '-0500', # Colombia Time                     UTC-05:00
      'CST'   => '-0600', # Central Standard Time (North America) UTC-06:00
      #'CST'  => '+0800', # China Standard Time               UTC+08:00
      #'CVT'  => '-0100', # Cape Verde Time                   UTC-01:00
      #'CXT'  => '+0700', # Christmas Island Time             UTC+07:00
      #'ChST' => '+1000', # Chamorro Standard Time            UTC+10:00
      # 'DST' => ''       # Daylight saving time              Depending
      #'DFT'  => '+0100', # AIX specific equivalent of Central European Time  UTC+01:00
      #'EAST' => '-0600', # Easter Island Standard Time       UTC-06:00
      #'EAT'  => '+0300', # East Africa Time                  UTC+03:00
      #'ECT'  => '-0400', # Eastern Caribbean Time (does not recognise DST)   UTC-04:00
      #'ECT'  => '-0500', # Ecuador Time                      UTC-05:00
      'EDT'   => '-0400', # Eastern Daylight Time (North America)     UTC-04:00
      #'EEDT' => '+0300', # Eastern European Daylight Time    UTC+03:00
      #'EEST' => '+0300', # Eastern European Summer Time      UTC+03:00
      #'EET'  => '+0200', # Eastern European Time             UTC+02:00
      'EST'   => '+0500', # Eastern Standard Time (North America) UTC-05:00
      #'FJT'  => '+1200', # Fiji Time                         UTC+12:00
      #'FKST' => '-0400', # Falkland Islands Standard Time    UTC-04:00
      #'GALT' => '-0600', # Galapagos Time                    UTC-06:00
      #'GET'  => '+0400', # Georgia Standard Time             UTC+04:00
      #'GFT'  => '-0300', # French Guiana Time                UTC-03:00
      #'GILT' => '+1200', # Gilbert Island Time               UTC+12:00
      #'GIT'  => '-0900', # Gambier Island Time               UTC-09:00
      'GMT'   => '+0000', # Greenwich Mean Time               UTC
      #'GST'  => '-0200', # South Georgia and the South Sandwich Islands  UTC-02:00
      #'GYT'  => '-0400', # Guyana Time                       UTC-04:00
      'HADT'  => '-0900', # Hawaii-Aleutian Daylight Time     UTC-09:00
      'HAST'  => '-1000', # Hawaii-Aleutian Standard Time     UTC-10:00
      #'HKT'  => '+0800', # Hong Kong Time                    UTC+08:00
      #'HMT'  => '+0500', # Heard and McDonald Islands Time   UTC+05:00
      'HST'   => '-1000', # Hawaii Standard Time              UTC-10:00
      #'IRKT' => '+0800', # Irkutsk Time                      UTC+08:00
      #'IRST' => '+0330', # Iran Standard Time                UTC+03:30
      #'IST'  => '+0530', # Indian Standard Time              UTC+05:30
      #'IST'  => '+0100', # Irish Summer Time                 UTC+01:00
      #'IST'  => '+0200', # Israel Standard Time              UTC+02:00
      'JST'   => '+0900', # Japan Standard Time               UTC+09:00
      #'KRAT' => '+0700', # Krasnoyarsk Time                  UTC+07:00
      #'KST'  => '+0900', # Korea Standard Time               UTC+09:00
      #'LHST' => '+1030', # Lord Howe Standard Time           UTC+10:30
      #'LINT' => '+1400', # Line Islands Time                 UTC+14:00
      #'MAGT' => '+1100', # Magadan Time                      UTC+11:00
      'MDT'   => '-0600', # Mountain Daylight Time(North America) UTC-06:00
      #'MIT'  => '-0930', # Marquesas Islands Time            UTC-09:30
      #'MSD'  => '+0400', # Moscow Summer Time                UTC+04:00
      #'MSK'  => '+0300', # Moscow Standard Time              UTC+03:00
      #'MST'  => '+0800', # Malaysian Standard Time           UTC+08:00
      'MST'   => '-0700', # Mountain Standard Time(North America) UTC-07:00
      #'MST'  => '+0630', # Myanmar Standard Time             UTC+06:30
      #'MUT'  => '+0400', # Mauritius Time                    UTC+04:00
      #'NDT'  => '-0230', # Newfoundland Daylight Time        UTC-02:30
      #'NFT'  => '+1130', # Norfolk Time[1]                   UTC+11:30
      #'NPT'  => '+0545', # Nepal Time                        UTC+05:45
      #'NST'  => '-0330', # Newfoundland Standard Time        UTC-03:30
      #'NT'   => '-0330', # Newfoundland Time                 UTC-03:30
      #'OMST' => '+0600', # Omsk Time                         UTC+06:00
      'PDT'   => '-0700', # Pacific Daylight Time(North America)  UTC-07:00
      #'PETT' => '+1200', # Kamchatka Time                    UTC+12:00
      #'PHOT' => '+1300', # Phoenix Island Time               UTC+13:00
      #'PKT'  => '+0500', # Pakistan Standard Time            UTC+05:00
      'PST'   => '-0800', # Pacific Standard Time (North America) UTC-08:00
      #'PST'  => '+0800', # Philippine Standard Time          UTC+08:00
      #'RET'  => '+0400', # Reunion Time                      UTC+04:00
      #'SAMT' => '+0400', # Samara Time                       UTC+04:00
      #'SAST' => '+0200', # South African Standard Time       UTC+02:00
      #'SBT'  => '+1100', # Solomon Islands Time              UTC+11:00
      #'SCT'  => '+0400', # Seychelles Time                   UTC+04:00
      #'SLT'  => '+0530', # Sri Lanka Time                    UTC+05:30
      #'SST'  => '-1100', # Samoa Standard Time               UTC-11:00
      #'SST'  => '+0800', # Singapore Standard Time           UTC+08:00
      #'TAHT' => '-1000', # Tahiti Time                       UTC-10:00
      #'THA'  => '+0700', # Thailand Standard Time            UTC+07:00
      'UT'    => '-0000', # Coordinated Universal Time        UTC
      'UTC'   => '-0000', # Coordinated Universal Time        UTC
      #'UYST' => '-0200', # Uruguay Summer Time               UTC-02:00
      #'UYT'  => '-0300', # Uruguay Standard Time             UTC-03:00
      #'VET'  => '-0430', # Venezuelan Standard Time          UTC-04:30
      #'VLAT' => '+1000', # Vladivostok Time                  UTC+10:00
      #'WAT'  => '+0100', # West Africa Time                  UTC+01:00
      #'WEDT' => '+0100', # Western European Daylight Time    UTC+01:00
      #'WEST' => '+0100', # Western European Summer Time      UTC+01:00
      #'WET'  => '-0000', # Western European Time             UTC
      #'YAKT' => '+0900', # Yakutsk Time                      UTC+09:00
      #'YEKT' => '+0500', # Yekaterinburg Time                UTC+05:00
    }

    # Convert to second
    # @param    [String] argvs  Digit and a unit of time
    # @return   [Integer]       n: seconds
    #                           0: 0 or invalid unit of time
    # @example  Get the value of seconds
    #   to_second('1d') #=> 86400
    #   to_second('2h') #=>  7200
    def to_second( argvs )
      return 0 unless argvs.kind_of?(String)

      getseconds = 0
      unitoftime = @@TimeUnit.keys.join
      mathconsts = @@MathematicalConstant.keys.join

      if vm = argvs.match(/\A(\d+|\d+[.]\d+)([#{unitoftime}])?\z/) then
        # 1d, 1.5w
        n = vm[1].to_f
        u = vm[2] || 'd'
        getseconds = n * @@TimeUnit[ u ].to_f

      elsif vm = argvs.match(/\A(\d+|\d+[.]\d+)?([#{mathconsts}])([#{unitoftime}])?\z/) then
        # 1pd, 1.5pw
        n = vm[1].to_f || 1
        n = 1 if n.to_i == 0
        m = @@MathematicalConstant[ vm[2] ].to_f
        u = vm[3] || 'd'
        getseconds = n * m * @@TimeUnit[ u ].to_f

      else
        getseconds = 0

      end

      return getseconds
    end

    # Month name list
    # @param    [Integer] argvs  Require full name or not
    # @return   [Array, String]  Month name list or month name
    # @example  Get the names of each month
    #   monthname()  #=> [ 'Jan', 'Feb', ... ]
    #   monthname(1) #=> [ 'January', 'February', 'March', ... ]
    def monthname( argvs=0 )
      value = argvs > 0 ? 'full' : 'abbr'
      return @@MonthName[ value ]
    end

    # List of day of week
    # @param    [Integer] argvs Require full name
    # @return   [Array, String] List of day of week or day of week
    # @example  Get the names of each day of week
    #   dayofweek()  #=> [ 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat' ]
    #   dayofweek(1) #=> [ 'Sunday', 'Monday', 'Tuesday', ... ]
    def dayofweek( argvs=0 )
      value = argvs > 0 ? 'full' : 'abbr'
      return @@DayOfWeek[ value ]
    end

    # Hour name list
    # @param    [Integer] argvs Require full name
    # @return   [Array, String] Month name
    # @example  Get the names of each hour
    #   hourname()  #=> [ 0, 1, 2, ... 23 ]
    #   hourname(1) #=> [ 'Midnight', 1, 2, ... 'Morning', 7, ... 'Noon', ... 23 ]
    def hourname( argvs=1 )
      value = argvs > 0 ? 'full' : 'abbr'
      return @@HourName[ value ]
    end

    # Convert from date offset to date string
    # @param    [Integer] argv1 Offset of
    # @param    [String]  argv2 Delimiter character: default is '-'
    # @return   [String]        Date string
    # @example  Get the value of n days before(today is 2015/11/04)
    #   o2d(1)      #=> 2015-11-03
    #   o2d(2,'/')  #=> 2015/11/02
    def o2d( argv1=0, argv2='-' )
      piece = DateTime.now()
      epoch = 0

      return piece.strftime("%Y/%m/%d") unless argv1 =~ /\A[-]?\d+\z/
      epoch = piece.to_time.to_i - argv1 * 86400

      if epoch < 0 then
        # Negative value
        epoch = 0

      elsif epoch >= 2 ** 31 then
        # See http://en.wikipedia.org/wiki/Year_2038_problem
        epoch = 2 ** 31 - 1
      end
      return Time.at(epoch).strftime( "%Y" + argv2 + "%m" + argv2 + "%d" )
    end

    # Parse date string; strptime() wrapper
    # @param    [String] argvs  Date string
    # @return   [String]        Converted date string
    # @see      http://en.wikipedia.org/wiki/ISO_8601
    # @see      http://www.ietf.org/rfc/rfc3339.txt
    # @example  Parse date string and convert to generic format string
    #   parse("2015-11-03T23:34:45 Tue")    #=> Tue, 3 Nov 2015 23:34:45 +0900
    #   parse("Tue, Nov 3 2015 2:2:2")      #=> Tue, 3 Nov 2015 02:02:02 +0900
    def parse( argvs )
      return nil unless argvs.kind_of?(String)

      datestring = argvs
      datestring = datestring.sub(/[,](\d+)/, ', \1')  # Thu,13 -> Thu, 13
      timetokens = datestring.split(' ')
      parseddate = ''   # (String) Canonified Date/Time string
      afternoon1 = 0    # (Integer) After noon flag
      v = {
        'Y' => nil,   # (Integer) Year
        'M' => nil,   # (String) Month Abbr.
        'd' => nil,   # (Integer) Day
        'a' => nil,   # (String) Day of week, Abbr.
        'T' => nil,   # (String) Time
        'z' => nil,   # (Integer) Timezone offset
      }

      while p = timetokens.shift do
        # Parse each piece of time
        if p.match(/\A[A-Z][a-z]{2}[,]?\z/) then
          # Day of week or Day of week; Thu, Apr, ...
          p.chop if p.length == 4 # Thu, -> Thu

          if @@DayOfWeek['abbr'].include?(p) then
            # Day of week; Mon, Thu, Sun,...
            v['a'] = p

          elsif @@MonthName['abbr'].include?(p) then
            # Month name abbr.; Apr, May, ...
            v['M'] = p

          end

        elsif p.match(/\A\d{1,4}\z/) then
          # Year or Day; 2005, 31, 04,  1, ...
          if p.to_i > 31 then
            # The piece is the value of an year
            v['Y'] = p

          else
            # The piece is the value of a day
            v['d'] ||= p

          end

        elsif vm = p.match(/\A([0-2]\d):([0-5]\d):([0-5]\d)\z/) ||
              vm = p.match(/\A(\d{1,2})[-:](\d{1,2})[-:](\d{1,2})\z/) then
          # Time; 12:34:56, 03:14:15, ...
          # Arrival-Date: 2014-03-26 00-01-19

          if vm[1].to_i < 24 && vm[2].to_i < 60 && vm[3].to_i < 60 then
            # Valid time format, maybe...
            v['T'] = sprintf( "%02d:%02d:%02d", vm[1].to_i, vm[2].to_i, vm[3].to_i )
          end

        elsif vm = p.match(/\A([0-2]\d):([0-5]\d)\z/) then
          # Time; 12:34 => 12:34:00
          if vm[1].to_i < 24 && vm[2].to_i < 60 then
              v['T'] = sprintf( "%02d:%02d:00", vm[1], vm[2] )
          end

        elsif vm = p.match(/\A(\d\d?):(\d\d?)\z/) then
          # Time: 1:4 => 01:04:00
          v['T'] = sprintf( "%02d:%02d:00", vm[1], vm[2] )

        elsif p.match(/\A[APap][Mm]\z/) then
          # AM or PM
          afternoon1 = 1

        else
          # Timezone offset and others
          if p.match(/\A[-+][01]\d{3}\z/) then
            # Timezone offset; +0000, +0900, -1000, ...
            v['z'] ||= p

          elsif p.match(/\A[(]?[A-Z]{2,5}[)]?\z/) then
            # Timezone abbreviation; JST, GMT, UTC, ...
            v['z'] ||= self.abbr2tz(p) || '+0000'

          else
            # Other date format
            if vm = p.match(%r|\A(\d{4})[-/](\d{1,2})[-/](\d{1,2})\z|) then
              # Mail.app(MacOS X)'s faked Bounce, Arrival-Date: 2010-06-18 17:17:52 +0900
              v['Y'] = vm[1].to_i
              v['M'] = @@MonthName['abbr'][ vm[2].to_i - 1 ]
              v['d'] = vm[3].to_i

            elsif vm = p.match(%r|\A(\d{4})[-/](\d{1,2})[-/](\d{1,2})T([0-2]\d):([0-5]\d):([0-5]\d)\z|) then
              # ISO 8601; 2000-04-29T01:23:45
              v['Y'] = vm[1].to_i
              v['M'] = @@MonthName['abbr'][ vm[2].to_i - 1 ]

              if vm[3].to_i < 32 then
                v['d'] = vm[3].to_i
              end

              if vm[4].to_i < 24 && vm[5].to_i < 60 && vm[6].to_i < 60 then
                v['T'] = sprintf( "%02d:%02d:%02d", vm[4], vm[5], vm[6] )
              end

            elsif vm = p.match(%r|\A(\d{1,2})/(\d{1,2})/(\d{1,2})\z|) then
              # 4/29/01 11:34:45 PM
              v['M']  = @@MonthName['abbr'][ vm[1].to_i - 1 ]
              v['d']  = vm[2].to_i
              v['Y']  = vm[3].to_i + 2000
              v['Y'] -= 100 if v['Y'].to_i > DateTime.now().year + 1
            end
          end
        end
      end # End of while()

      if v['T'] && afternoon1 > 0 then
        # +12
        t0 = v['T']
        t1 = v['T'].split(':')
        v['T'] = sprintf( "%02d:%02d:%02d", t1[0].to_i + 12, t1[1], t1[2] )
        v['T'] = t0 if t1[0].to_i > 12;
      end
      v['a'] ||= 'Thu' # There is no day of week

      if ! v['Y'].nil? && v['Y'].to_i < 200 then
        # 99 -> 1999, 102 -> 2002
        v['Y'] = v['Y'].to_i + 1900
      end
      v['z'] ||= DateTime.now().zone.tr(':','')

      # Check each piece
      if v.has_value?(nil) then
        # Strange date format
        warn sprintf( " ***warning: Strange date format [%s]", datestring )
        return nil
      end

      if v['Y'].to_i < 1902 || v['Y'].to_i > 2037 then
        # -(2^31) ~ (2^31)
        return nil
      end

      # Build date string
      #   Thu, 29 Apr 2004 10:01:11 +0900
      parseddate = sprintf( "%s, %d %s %d %s %s",
                      v['a'], v['d'], v['M'], v['Y'], v['T'], v['z'] )
      return parseddate;
    end

    # Abbreviation -> Tiemzone
    # @param    [String] argvs  Abbr. e.g.) JST, GMT, PDT
    # @return   [String, Undef] +0900, +0000, -0600 or Undef if the argument is
    #                           invalid format or not supported abbreviation
    # @example  Get the timezone string of "JST"
    #   abbr2tz('JST')  #=> '+0900'
    def abbr2tz( argvs )
      return nil unless argvs.kind_of?(String)
      return @@TimeZoneAbbr[ argvs ]
    end

    # Convert to second
    # @param    [String] argvs  Timezone string e.g) +0900
    # @return   [Integer,Undef] n: seconds or Undef it the argument is invalid
    #                           format string
    # @see      second2tz
    # @example  Convert '+0900' to seconds
    #   tz2second('+0900')  #=> 32400
    def tz2second( argvs )
      return nil unless argvs.kind_of?(String)
      digit = {}
      ztime = 0

      if vm = argvs.match(/\A([-+])(\d)(\d)(\d{2})\z/) then
        digit = {
            'operator' => vm[1],
            'hour-10'  => vm[2].to_i,
            'hour-01'  => vm[3].to_i,
            'minutes'  => vm[4].to_i,
        }
        ztime += ( digit['hour-10'] * 10 + digit['hour-01'] ) * 3600
        ztime += ( digit['minutes'] * 60 )
        ztime *= -1 if digit['operator'] == '-'

        return nil if ztime.abs > TZ_OFFSET
        return ztime

      elsif argvs.match(/\A[A-Za-z]+\z/) then
        return self.tz2second( @@TimeZoneAbbr[ argvs ] )

      else
        return nil
      end
    end

    # Convert to Timezone string
    # @param    [Integer] argvs Second to be converted
    # @return   [String]        Timezone offset string
    # @see      tz2second
    # @example  Get timezone offset string of specified seconds
    #   second2tz(12345)    #=> '+0325'
    def second2tz( argvs )
      return '+0000' unless argvs.kind_of?(Number)
      digit = { 'operator' => '+' }
      timez = ''

      return '' if argvs.abs() > TZ_OFFSET  # UTC+14 + 1(DST?)
      digit['operator'] = '-' if argvs < 0
      digit['hours']    = ( argvs.abs() / 3600 ).to_i
      digit['minutes']  = ( ( argvs.abs() % 3600 ) / 60 ).to_i

      timez = sprintf( "%s%02d%02d", digit['operator'], digit['hours'], digit['minutes'] )
      return timez
    end
  end

end

