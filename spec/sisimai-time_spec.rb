require 'spec_helper'
require 'sisimai/time'
require 'date'

describe 'Sisimai::Time' do
  describe 'Sisimai::Time.to_second() method' do
    it 'to_second(1d) returns 86400 seconds' do
      expect(Sisimai::Time.to_second('1d')).to eq 86400
    end
    it 'to_second(2w) returns ( 86400 * 7 * 2 ): 2 weeks' do
      expect(Sisimai::Time.to_second('2w')).to eq ( 86400 * 7 * 2 )
    end
    it 'to_second(3f) returns ( 86400 * 14 * 3 ): 3 fortnights' do
      expect(Sisimai::Time.to_second('3f')).to eq ( 86400 * 14 * 3 )
    end
    it 'to_second(4l) returns 10205771: 4 Lunar months' do
      expect(Sisimai::Time.to_second('4l').to_i).to eq 10205771
    end
    it 'to_second(5q) returns 39446190: 5 Quarters' do
      expect(Sisimai::Time.to_second('5q').to_i).to eq 39446190
    end
    it 'to_second(6y) returns 189341712: 6 Years' do
      expect(Sisimai::Time.to_second('6y')).to eq 189341712
    end
    it 'to_second(7o) returns 883594656: 7 Olympiads' do
      expect(Sisimai::Time.to_second('7o')).to eq 883594656
    end
    it 'to_second(gs) returns 23: 23.14(e^p) Seconds' do
      expect(Sisimai::Time.to_second('gs').to_i).to eq 23
    end
    it 'to_second(pm) returns 188: 3.14(PI) minutes' do
      expect(Sisimai::Time.to_second('pm').to_i).to eq 188
    end
    it 'to_second(pm) returns 9785: 2.718(e) hours' do
      expect(Sisimai::Time.to_second('eh').to_i).to eq 9785
    end
    it 'to_second(-1) returns 0' do
      expect(Sisimai::Time.to_second(-1)).to eq 0
    end
    it 'to_second(-4294967296) returns 0' do
      expect(Sisimai::Time.to_second(-4294967296)).to eq 0
    end
    it 'to_second(nil) returns 0' do
      expect(Sisimai::Time.to_second(nil)).to eq 0
    end
    it 'to_second(1x) returns 0' do
      expect(Sisimai::Time.to_second('1x')).to eq 0
    end

    context 'Errors from the method' do
      it 'to_second(x,y) raise an error: ArgumentError' do
        expect { Sisimai::Time.to_second('x','y') }.to raise_error(ArgumentError)
      end
      it 'to_second(x,y,z) raise an error: ArgumentError' do
        expect { Sisimai::Time.to_second('x','y','z') }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'Sisimai::Time.monthname() method' do
    month0=Sisimai::Time.monthname(0)
    month1=Sisimai::Time.monthname(1)
    it 'monthname(0) returns an array' do
      expect(month0.kind_of?(Array)).to be_true
    end
    it 'monthname(1) returns an array' do
      expect(month1.kind_of?(Array)).to be_true
    end
    context 'Returned data from the method' do
      it 'monthname(0)->[0] returns "Jan"' do
        expect(month0[0]).to eq 'Jan'
      end
      it 'monthname(0)->[3] returns "Apr"' do
        expect(month0[3]).to eq 'Apr'
      end
      it 'monthname(0)->[6] returns "Jul"' do
        expect(month0[6]).to eq 'Jul'
      end
      it 'monthname(1)->[1] returns "February"' do
        expect(month1[1]).to eq 'February'
      end
      it 'monthname(1)->[4] returns "May"' do
        expect(month1[4]).to eq 'May'
      end
      it 'monthname(1)->[7] returns "August"' do
        expect(month1[7]).to eq 'August'
      end
    end
    context 'Errors from the method' do
      it 'monthname(x) raise an error: ArgumentError' do
        expect { Sisimai::Time.monthname('x') }.to raise_error(ArgumentError)
      end
      it 'monthname(x,y) raise an error: ArgumentError' do
        expect { Sisimai::Time.monthname('x','y') }.to raise_error(ArgumentError)
      end
      it 'monthname(x,y,z) raise an error: ArgumentError' do
        expect { Sisimai::Time.monthname('x','y','z') }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'Sisimai::Time.dayofweek() method' do
    dayofweek0=Sisimai::Time.dayofweek(0)
    dayofweek1=Sisimai::Time.dayofweek(1)
    it 'dayofweek(0) returns an array' do
      expect(dayofweek0.kind_of?(Array)).to be_true
    end
    it 'dayofweek(1) returns an array' do
      expect(dayofweek1.kind_of?(Array)).to be_true
    end
    context 'Returned data from the method' do
      it 'dayofweek(0)->[0] returns "Sun"' do
        expect(dayofweek0[0]).to eq 'Sun'
      end
      it 'dayofweek(0)->[3] returns "Wed"' do
        expect(dayofweek0[3]).to eq 'Wed'
      end
      it 'dayofweek(1)->[1] returns "Monday"' do
        expect(dayofweek1[1]).to eq 'Monday'
      end
      it 'dayofweek(1)->[4] returns "Thursday"' do
        expect(dayofweek1[4]).to eq 'Thursday'
      end
    end
    context 'Errors from the method' do
      it 'dayofweek(x) raise an error: ArgumentError' do
        expect { Sisimai::Time.dayofweek('x') }.to raise_error(ArgumentError)
      end
      it 'dayofweek(x,y) raise an error: ArgumentError' do
        expect { Sisimai::Time.dayofweek('x','y') }.to raise_error(ArgumentError)
      end
      it 'dayofseek(x,y,z) raise an error: ArgumentError' do
        expect { Sisimai::Time.dayofweek('x','y','z') }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'Sisimai::Time.hourname() method' do
    hourname1=Sisimai::Time.hourname(1)
    it 'hourname(1) returns an array' do
      expect(hourname1.kind_of?(Array)).to be_true
    end
    context 'Returned data from the method' do
      it 'hourname(1)->[0] returns "Midnight"' do
        expect(hourname1[0]).to eq 'Midnight'
      end
      it 'hourname(1)->[6] returns "Morning"' do
        expect(hourname1[6]).to eq 'Morning'
      end
      it 'hourname(1)->[12] returns "Noon"' do
        expect(hourname1[12]).to eq 'Noon'
      end
      it 'hourname(1)->[18] returns "Evening"' do
        expect(hourname1[18]).to eq 'Evening'
      end
    end
    context 'Errors from the method' do
      it 'hourname(x) raise an error: ArgumentError' do
        expect { Sisimai::Time.hourname('x') }.to raise_error(ArgumentError)
      end
      it 'hourname(x,y) raise an error: ArgumentError' do
        expect { Sisimai::Time.hourname('x','y') }.to raise_error(ArgumentError)
      end
      it 'hourname(x,y,z) raise an error: ArgumentError' do
        expect { Sisimai::Time.hourname('x','y','z') }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'Sisimai::Time.parse() method' do
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
    ]
    invaliddates = [
      'Thu, 13 Cat 2000 22:22:22 +2222',
      'Thu, 17 Apr 1192 12:46:23 +0900',
      'Thu, 19 May 2600 14:51:10 +0900',
      'Thu, 22 Jun 2001 32:40:29 +0900',
      'Thu, 25 Jul 1995 00:86:00 +0900',
      'Thu, 31 Aug 2013 11:22:73 +0900',
      'Thu, 36 Sep 2009 11:22:33 +0900',
    ]
    for v in datestrings do
      text = Sisimai::Time.parse( v )
      it 'parse() returns a text' do
        expect(text.kind_of?(String)).to be_true
      end
      date = text.sub(/\s[-+]\d{4}\z/,'')
      time = Time.strptime( date, '%a, %d %b %Y %T' )
      it 'Kind of "time" object is "Time"' do
        expect(time.kind_of?(Time)).to be_true 
      end
    end
    for v in invaliddates do
      null = Sisimai::Time.parse( v )
      it 'parse( ' + v + ') returns nil' do
        expect(null).to be_nil
      end
    end
  end

end




