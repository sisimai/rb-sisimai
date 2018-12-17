require 'spec_helper'
require 'sisimai/datetime'
require 'time'

describe Sisimai::DateTime do
  describe '.to_second' do
    context 'integer + supported unit string' do
      it 'returns converted seconds value' do
        expect(Sisimai::DateTime.to_second('1d')).to be == 86400
        expect(Sisimai::DateTime.to_second('2w')).to be == 86400 * 7 * 2
        expect(Sisimai::DateTime.to_second('3f')).to be == 86400 * 14 * 3
        expect(Sisimai::DateTime.to_second('4l').to_i).to be == 10205771
        expect(Sisimai::DateTime.to_second('5q').to_i).to be == 39446190
        expect(Sisimai::DateTime.to_second('6y')).to be == 189341712
        expect(Sisimai::DateTime.to_second('7o')).to be == 883594656
      end
    end

    context 'integer alias string + supported unit string' do
      it 'returns converted seconds value' do
        expect(Sisimai::DateTime.to_second('gs').to_i).to be == 23
        expect(Sisimai::DateTime.to_second('pm').to_i).to be == 188
        expect(Sisimai::DateTime.to_second('eh').to_i).to be == 9785
      end
    end

    context 'negative integer OR unsupported unit string' do
      it 'always returns 0' do
        expect(Sisimai::DateTime.to_second(-1)).to be ==  0
        expect(Sisimai::DateTime.to_second(-4294967296)).to be ==  0
        expect(Sisimai::DateTime.to_second('1x')).to be == 0
        expect(Sisimai::DateTime.to_second(nil)).to be == 0
      end
    end

    context 'wrong number of arguments' do
      it 'raises ArgumentError' do
        expect { Sisimai::DateTime.to_second('x', 'y') }.to raise_error(ArgumentError)
        expect { Sisimai::DateTime.to_second('x', 'y', 'z') }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.monthname' do
    month0 = Sisimai::DateTime.monthname(0)
    month1 = Sisimai::DateTime.monthname(1)

    context 'integer' do
      it 'returns Array' do
        expect(month0).to be_a Array
        expect(month1).to be_a Array
      end

      context '(0)' do
        it 'returns short month name' do
          expect(month0[0]).to be == 'Jan'
          expect(month0[3]).to be == 'Apr'
          expect(month0[6]).to be == 'Jul'
        end
      end

      describe '(1)' do
        it 'returns month name' do
          expect(month1[1]).to be == 'February'
          expect(month1[4]).to be == 'May'
          expect(month1[7]).to be == 'August'
        end
      end
    end

    context 'wrong number of arguments' do
      it 'raises ArgumentError' do
        expect { Sisimai::DateTime.monthname('x') }.to raise_error(ArgumentError)
        expect { Sisimai::DateTime.monthname('x','y') }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.dayofweek' do
    dayofweek0 = Sisimai::DateTime.dayofweek(0)
    dayofweek1 = Sisimai::DateTime.dayofweek(1)

    context 'integer' do
      it 'returns Array' do
        expect(dayofweek0).to be_a Array
        expect(dayofweek1).to be_a Array
      end
    end

    context '(0)' do
      it 'returns short day name' do
        expect(dayofweek0[0]).to be == 'Sun'
        expect(dayofweek0[3]).to be == 'Wed'
      end
    end

    context '(1)' do
      it 'returns day name' do
        expect(dayofweek1[1]).to be == 'Monday'
        expect(dayofweek1[4]).to be == 'Thursday'
      end
    end

    context 'wrong number of arguments' do
      it 'raises ArgumentError' do
        expect { Sisimai::DateTime.dayofweek('x') }.to raise_error(ArgumentError)
        expect { Sisimai::DateTime.dayofweek('x', 'y') }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'parse' do
    context 'valid date string' do
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
        text = Sisimai::DateTime.parse(e)
        date = text.sub(/\s[-+]\d{4}\z/,'')
        time = Time.strptime(date, '%a, %d %b %Y %T')

        describe e do
          it 'returns parsed date string with timestamp' do
            expect(text).to be_a String
            expect(text.size).to be > 0
          end

          it 'returns parsed date string' do
            expect(date).to be_a String
            expect(date.size).to be > 0
          end

          it 'could be converted to Time object' do
            expect(time).to be_a Time
          end
        end
      end
    end

    context 'invalid date string' do
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
        text = Sisimai::DateTime.parse(e)
        describe e do
          it 'always returns nil' do
            expect(text).to be nil
          end
        end
      end
    end

  end

  describe '.abbr2tz' do
    context 'valid timezone abbreviation string' do
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

      it 'returns timezone offset value' do
        tzmap.each do |x,y|
          expect(Sisimai::DateTime.abbr2tz(x)).to be == y
        end
      end
    end

    context 'invalid argument' do
      it 'always returns nil' do
        expect(Sisimai::DateTime.abbr2tz(0)).to be nil
        expect(Sisimai::DateTime.abbr2tz('a')).to be nil
      end
    end

    context 'wrong number of arguments' do
      it 'raises ArgumentError' do
        expect { Sisimai::DateTime.abbr2tz }.to raise_error(ArgumentError)
        expect { Sisimai::DateTime.abbr2tz(nil, nil) }.to raise_error(ArgumentError)
      end
    end

  end

  describe '.tz2second' do
    context 'valid timezone offset string' do
      tzmap = {
        '+0000' => 0,
        '-0000' => 0,
        '-0900' => -32400,
        '+0900' => 32400,
        '-1200' => -43200,
        '+1200' => 43200,
      }
      it 'returns timezome offset value(second)' do
        tzmap.each do |x,y|
          expect(Sisimai::DateTime.tz2second(x)).to be == y
        end
      end
    end

    context 'invalid argument' do
      context 'Out of Range' do
        it 'always returns nil' do
          expect(Sisimai::DateTime.tz2second('-1800')).to be nil
          expect(Sisimai::DateTime.tz2second('+1800')).to be nil
        end
      end

      context 'not timezone offset' do
        it 'always returns nil' do
          expect(Sisimai::DateTime.tz2second('nil')).to be nil
          expect(Sisimai::DateTime.tz2second(nil)).to be nil
        end
      end
    end

    context 'wrong number of arguments' do
      it 'raises ArgumentError' do
        expect { Sisimai::DateTime.tz2second }.to raise_error(ArgumentError)
        expect { Sisimai::DateTime.tz2second(nil, nil) }.to raise_error(ArgumentError)
      end
    end
  end
end

