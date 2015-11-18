require 'spec_helper'
require 'sisimai/datetime'
require 'date'
require 'time'

describe Sisimai::DateTime do
  cn = Sisimai::DateTime
  describe '.to_second' do
    context 'Integer + Supported Unit String' do
      example('"1d" returns 86400 seconds')           { expect(cn.to_second('1d')).to eq 86400 }
      example('"2w" returns 1209600(2 weeks)')        { expect(cn.to_second('2w')).to eq (86400 * 7 * 2) }
      example('"3f" returns 3628800(3 fortnights)')   { expect(cn.to_second('3f')).to eq (86400 * 14 * 3) }
      example('"4l" returns 10205771(4 Lunar months)'){ expect(cn.to_second('4l').to_i).to eq 10205771 }
      example('"5q" returns 39446190(5 Quarters)')    { expect(cn.to_second('5q').to_i).to eq 39446190 }
      example('"6y" returns 189341712(6 Years)')      { expect(cn.to_second('6y')).to eq 189341712 }
      example('"7o" returns 883594656(7 Olympiads)')  { expect(cn.to_second('7o')).to eq 883594656 }
    end

    context 'Integer Alias String + Supported Unit String' do
      example('"gs" returns 23(23.14(e^p))')  { expect(cn.to_second('gs').to_i).to eq 23 }
      example('"pm" returns 188(3.14(PI))')   { expect(cn.to_second('pm').to_i).to eq 188 }
      example('"pm" returns 9785(2.718(e))')  { expect(Sisimai::DateTime.to_second('eh').to_i).to eq 9785 }
    end

    context 'Negative Integer OR Unsupported Unit String' do
      example('-1 returns 0')           { expect(cn.to_second(-1)).to eq 0 }
      example('-4294967296 returns 0')  { expect(cn.to_second(-4294967296)).to eq 0 }
      example('"1x" returns 0')         { expect(cn.to_second('1x')).to eq 0 }
      example('nil returns 0')          { expect(cn.to_second(nil)).to eq 0 }
    end

    context 'Wrong number of Arguments' do
      example('"x","y" raises ArgumentError')     { expect { cn.to_second('x','y') }.to raise_error(ArgumentError) }
      example('"x","y","z" raises ArgumentError') { expect { cn.to_second('x','y','z') }.to raise_error(ArgumentError) }
    end
  end

  describe '.monthname' do
    month0 = cn.monthname(0)
    month1 = cn.monthname(1)

    context 'Integer' do
      example('(0) returns Array') { expect(month0.kind_of?(Array)).to be true }
      example('(1) returns Array') { expect(month1.kind_of?(Array)).to be true }

      describe month0 do
        example('[0] is "Jan"') { expect(month0[0]).to eq 'Jan' }
        example('[3] is "Apr"') { expect(month0[3]).to eq 'Apr' }
        example('[6] is "Jul"') { expect(month0[6]).to eq 'Jul' }
      end

      describe month1 do
        example('[1] is "February"') { expect(month1[1]).to eq 'February' }
        example('[4] is "May"')      { expect(month1[4]).to eq 'May' }
        example('[7] is "August"')   { expect(month1[7]).to eq 'August' }
      end
    end

    context 'Wrong number of Arguments' do
      example('"x" raises ArgumentError')     { expect { cn.monthname('x') }.to raise_error(ArgumentError) }
      example('"x","y" raises ArgumentError') { expect { cn.monthname('x','y') }.to raise_error(ArgumentError) }
    end
  end

  describe '.dayofweek' do
    dayofweek0 = cn.dayofweek(0)
    dayofweek1 = cn.dayofweek(1)

    context 'Integer' do
      example('0 returns Array') { expect(dayofweek0.kind_of?(Array)).to be true }
      example('1 returns Array') { expect(dayofweek1.kind_of?(Array)).to be true }
    end

    context dayofweek0 do
      it('[0] is "Sun"')  { expect(dayofweek0[0]).to eq 'Sun' }
      it('[3] is "Wed"')  { expect(dayofweek0[3]).to eq 'Wed' }
    end

    context dayofweek1 do
      it('[1] is "Monday"')  { expect(dayofweek1[1]).to eq 'Monday' }
      it('[4] is "Thursday"'){ expect(dayofweek1[4]).to eq 'Thursday' }
    end

    context 'Wrong number of Arguments' do
      example('"x" raises ArgumentError')     { expect { cn.dayofweek('x') }.to raise_error(ArgumentError) }
      example('"x","y" raises ArgumentError') { expect { cn.dayofweek('x','y') }.to raise_error(ArgumentError) }
    end
  end

  describe '.hourname' do
    hourname1 = cn.hourname(1)

    context 'Integer' do
      example('1 returns Array') { expect(hourname1.kind_of?(Array)).to be true }

      describe hourname1 do
        it('[0] is "Midnight"') { expect(hourname1[0]).to eq 'Midnight' }
        it('[6] is "Morning"')  { expect(hourname1[6]).to eq 'Morning' }
        it('[12] is "Noon"')    { expect(hourname1[12]).to eq 'Noon' }
        it('[18] is "Evening"') { expect(hourname1[18]).to eq 'Evening' }
      end
    end

    context 'Wrong number of Arguments' do
      example('"x" raises ArgumentError')     { expect { cn.hourname('x') }.to raise_error(ArgumentError) }
      example('"x","y" raises ArgumentError') { expect { cn.hourname('x','y') }.to raise_error(ArgumentError) }
    end
  end

  describe 'parse' do
    context 'Valid Date String' do
      datestrings = [
        'Mon, 2 Apr 2001 04:01:03 +0900 (JST)',
        'Fri, 9 Apr 2004 04:01:03 +0000 (GMT)',
        'Thu, 5 Apr 2007 04:01:03 -0000 (UTC)',
        'Thu, 03 Mar 2010 12:46:23 +0900',
        'Thu, 17 Jun 2010 01:43:33 +0900',
        'Thu, 1 Apr 2010 20:51:58 +0900',
        'Thu, 01 Apr 2010 16:25:40 +0900',
        '27 Apr 2009 08:08:54 +0000',
        'Fri,18 Oct 2002 16:03:06 PM',
        '27 Sep 1998 00:51:27 -0400',
        'Sat, 21 Nov 1998 16:38:02 -0500 (EST)',
        'Sat, 21 Nov 1998 13:13:04 -0800 (PST)',
        '    Sat, 21 Nov 1998 15:40:24 -0600',
        'Thu, 19 Nov 98 06:53:46 +0100',
        '03 Apr 1998 09:59:35 +0200',
        '19 Mar 1998 20:55:10 +0100',
        '2010-06-18 17:17:52 +0900',
        '2010-06-18T17:17:52 +0900',
        'Foo, 03 Mar 2010 12:46:23 +0900',
        'Thu, 13 Mar 100 12:46:23 +0900',
        'Thu, 03 Mar 2001 12:46:23 -9900',
        'Thu, 03 Mar 2001 12:46:23 +9900',
        'Sat, 21 Nov 1998 13:13:04 -0800 (PST)    ',
        'Sat, 21 Nov 1998 13:13:04 -0800 (PST) JST',
        'Sat, 21 Nov 1998 13:13:04 -0800 (PST) Hoge',
        'Fri, 29 Apr 2013 02:31 +0900',
        'Sun, 29 Apr 2014 1:2:3 +0900',
        'Sun, 29 May 2014 1:2 +0900',
        '4/29/01 11:34:45 PM',
        '2014-03-26 00-01-19',
      ]

      datestrings.each do |e|
        text = cn.parse(e)
        date = text.sub(/\s[-+]\d{4}\z/,'')
        time = Time.strptime( date, '%a, %d %b %Y %T' )

        describe e do
          it { expect(text).to eq text }
          it { expect(text.kind_of?(String)).to be true }
          it { expect(date.kind_of?(String)).to be true }
          it { expect(time.kind_of?(Time)).to be true }
        end
      end
    end

    context 'Invalid Date String' do
      invaliddates = [
        'Thu, 13 Cat 2000 22:22:22 +2222',
        'Thu, 17 Apr 1192 12:46:23 +0900',
        'Thu, 19 May 2600 14:51:10 +0900',
        'Thu, 22 Jun 2001 32:40:29 +0900',
        'Thu, 25 Jul 1995 00:86:00 +0900',
        'Thu, 31 Aug 2013 11:22:73 +0900',
        'Thu, 36 Sep 2009 11:22:33 +0900',
      ]
      invaliddates.each do |e|
        text = cn.parse(e)
        describe e do
          it { expect(text).to be nil }
        end
      end
    end

  end

  describe '.abbr2tz' do
    context 'Valid Timezone Abbreviation String' do
      tzmap = {
        'GMT' => '+0000',
        'UTC' => '-0000',
        'JST' => '+0900',
        'PDT' => '-0700',
        'MST' => '-0700',
        'CDT' => '-0500',
        'EDT' => '-0400',
        'HST' => '-1000',
        'UT'  => '-0000',
      }
      
      tzmap.each do |x,y|
        example( x + " returns " + y ) { expect(cn.abbr2tz(x)).to eq y }
      end
    end

    context 'Invalid Argument' do
      example('0 returns nil')   { expect(cn.abbr2tz(0)).to be nil }
      example('"a" returns nil') { expect(cn.abbr2tz('a')).to be nil }
    end

    context 'Wrong number of Arguments' do
      example('"" raises ArgumentError')      { expect { cn.abbr2tz() }.to raise_error(ArgumentError) }
      example('nil,nil raises ArgumentError') { expect { cn.abbr2tz(nil,nil) }.to raise_error(ArgumentError) }
    end

  end

  describe '.tz2second' do
    context 'Valid Timezone Offset String' do
      tzmap = {
        '+0000' => 0,
        '-0000' => 0,
        '-0900' => -32400,
        '+0900' => 32400,
        '-1200' => -43200,
        '+1200' => 43200,
      }
      tzmap.each do |x,y|
        example( x + ' returns ' + y.to_s ) { expect(cn.tz2second( x )).to eq y }
      end
    end

    context 'Invalid Argument' do
      context 'Out of Range' do
        example('-1800 returns nil') { expect(cn.tz2second('-1800')).to be nil }
        example('+1800 returns nil') { expect(cn.tz2second('+1800')).to be nil }
      end

      context 'Not Timezone Offset' do
        example('"nil" returns nil') { expect(cn.tz2second('nil')).to be nil }
        example('nil returns nil')   { expect(cn.tz2second(nil)).to be nil }
      end
    end

    context 'Wrong number of Arguments' do
      example('() raises ArgumentError')      { expect { cn.tz2second() }.to raise_error(ArgumentError) }
      example('nil,nil raises ArgumentError') { expect { cn.tz2second(nil,nil) }.to raise_error(ArgumentError) }
    end
  end
end

