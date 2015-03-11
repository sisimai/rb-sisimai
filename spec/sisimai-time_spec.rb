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

end
