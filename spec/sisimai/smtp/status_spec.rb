require 'spec_helper'
require 'sisimai/smtp/status'

describe Sisimai::SMTP::Status do
  cn = Sisimai::SMTP::Status
  reasonlist = [ 
    'blocked', 'contenterror', 'exceedlimit', 'expired', 'filtered', 'hasmoved',
    'hostunknown', 'mailboxfull', 'mailererror', 'mesgtoobig', 'networkerror',
    'norelaying', 'notaccept', 'onhold', 'rejected', 'securityerror', 'spamdetected',
    'suspend', 'systemerror', 'systemfull', 'toomanyconn', 'userunknown',
  ]
  statuslist = %w/
    4.1.6 4.1.7 4.1.8 4.1.9 4.2.1 4.2.2 4.2.3 4.2.4 4.3.1 4.3.2 4.3.3 4.3.5
    4.4.1 4.4.2 4.4.4 4.4.5 4.4.6 4.4.7 4.5.3 4.5.5 4.6.0 4.6.2 4.6.5
    4.7.1 4.7.2 4.7.5 4.7.6 4.7.7
    5.1.0 5.1.1 5.1.2 5.1.3 5.1.4 5.1.6 5.1.7 5.1.8 5.1.9 5.2.0 5.2.1 5.2.2
    5.2.3 5.2.4 5.3.0 5.3.1 5.3.2 5.3.3 5.3.4 5.3.5 5.4.0 5.4.3 5.5.3 5.5.4
    5.5.5 5.5.6 5.6.0 5.6.1 5.6.2 5.6.3 5.6.5 5.6.6 5.6.7 5.6.8 5.6.9 5.7.0
    5.7.1 5.7.2 5.7.3 5.7.4 5.7.5 5.7.6 5.7.7 5.7.8 5.7.9
  /
  smtperrors = [
    'smtp;550 5.2.2 <mikeneko@example.co.jp>... Mailbox Full',
    'smtp; 550 5.1.1 Mailbox does not exist',
    'smtp; 550 5.1.1 Mailbox does not exist',
    'smtp; 450 4.0.0 Temporary failure',
    'smtp; 552 5.2.2 Mailbox full',
    'smtp; 552 5.3.4 Message too large',
    'smtp; 500 5.6.1 Message content rejected',
    'smtp; 550 5.2.0 Message Filtered',
    '550 5.1.1 <kijitora@example.jp>... User Unknown',
    'SMTP; 552-5.7.0 This message was blocked because its content presents a potential',
    'SMTP; 550 5.1.1 Requested action not taken: mailbox unavailable',
    'SMTP; 550 5.7.1 IP address blacklisted by recipient',
  ]

  describe '.code' do
    context 'empty string' do
      subject { cn.code('') }
      it('returns ""') { expect(cn.code('')).to be_empty }
    end

    context 'no 2nd argument' do
      reasonlist.each do |e|
        subject { cn.code(e) }
        it('matches with DSN') { is_expected.to match %r/\A5[.]\d[.]9\d+\z/ }
      end
    end

    context 'specify 2nd argument' do
      reasonlist.each do |e|
        subject { cn.code(e,1) }
        it('matches with DSN') { is_expected.to match %r/\A[45][.]\d[.]9\d+\z/ }
      end
    end

    context 'wrong number of arguments' do
      it 'raises ArgumentError' do
        expect { cn.code(nil, nil, nil) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.name' do
    context 'empty string' do
      subject { cn.name('') }
      it('returns ""') { is_expected.to be_empty }
    end

    context 'standard status code' do
      statuslist.each do |e|
        v = cn.name(e)
        subject { v }
        it('returns reason string') { is_expected.to be_a String }
        it('is included in reason list') { expect(reasonlist.index(v)).to be_a Integer }
      end
    end

    context 'wrong number of arguments' do
      it 'raises ArgumentError' do
        expect { cn.name(nil, nil) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.find' do
    context 'empty string' do
      subject { cn.find('') }
      it('returns ""') { is_expected.to be_empty }
    end

    context 'error message including DSN' do
      smtperrors.each do |e|
        subject { cn.find(e) }
        it('returns DSN') { is_expected.to be_a String }
        it('matches with DSN') { is_expected.to match /\A[45][.]\d[.]\d\z/ }
      end
    end

    context 'wrong number of arguments' do
      it 'raises ArgumentError' do
        expect { cn.find(nil, nil) }.to raise_error(ArgumentError)
      end
    end
  end

end
