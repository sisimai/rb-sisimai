require 'spec_helper'
require 'sisimai/smtp/error'

describe Sisimai::SMTP::Error do
  cn = Sisimai::SMTP::Error
  softbounces = [
    'blocked', 'contenterror', 'exceedlimit', 'expired', 'filtered',
    'mailboxfull', 'mailererror', 'mesgtoobig', 'networkerror',
    'norelaying', 'rejected', 'securityerror',
    'spamdetected', 'suspend', 'systemerror', 'systemfull', 'toomanyconn',
  ]
  hardbounces = ['userunknown', 'hostunknown', 'hasmoved', 'notaccept']
  isntbounces = ['delivered', 'feedback', 'vacation']
  dependondsn = ['undefined', 'onhold']

  isnterrors = [
    'smtp; 2.1.5 250 OK',
  ]
  temperrors = [
    'smtp; 450 4.0.0 Temporary failure',
  ]
  permerrors = [
    'smtp;550 5.2.2 <mikeneko@example.co.jp>... Mailbox Full',
    'smtp; 550 5.1.1 Mailbox does not exist',
    'smtp; 550 5.1.1 Mailbox does not exist',
    'smtp; 552 5.2.2 Mailbox full',
    'smtp; 552 5.3.4 Message too large',
    'smtp; 500 5.6.1 Message content rejected',
    'smtp; 550 5.2.0 Message Filtered',
    '550 5.1.1 <kijitora@example.jp>... User Unknown',
    'SMTP; 552-5.7.0 This message was blocked because its content presents a potential',
    'SMTP; 550 5.1.1 Requested action not taken: mailbox unavailable',
    'SMTP; 550 5.7.1 IP address blacklisted by recipient',
  ]

  describe '.is_permanent' do
    context 'empty string' do
      subject { cn.is_permanent('') }
      it('returns nil') { is_expected.to be_nil }
    end

    context 'valid argument' do
      context 'is not an error' do
        isnterrors.each do |e|
          subject { cn.is_permanent(e) }
          it('returns nil') { is_expected.to be_nil }
        end
      end

      context 'is a temporary error' do
        temperrors.each do |e|
          subject { cn.is_permanent(e) }
          it('returns false') { is_expected.to be false }
        end
      end

      context 'is a permanent error' do
        permerrors.each do |e|
          subject { cn.is_permanent(e) }
          it('returns true') { is_expected.to be true }
        end
      end
    end

    context 'wrong number of arguments' do
      it 'raises ArgumentError' do
        expect { cn.is_permanent(nil, nil) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.soft_or_hard' do
    context 'empty string' do
      subject { cn.soft_or_hard('') }
      it('returns ""') { is_expected.to be_empty }
    end

    context 'valid arguments' do
      context 'soft bounce' do
        softbounces.each do |e|
          v = cn.soft_or_hard(e)
          subject { v }
          it('returns String') { is_expected.to be_a String }
          it('returns "soft"') { is_expected.to be == 'soft' }
        end
      end

      context 'hard bounce' do
        hardbounces.each do |e|
          v = cn.soft_or_hard(e)
          subject { v }
          it('returns String') { is_expected.to be_a String }
          it('returns "hard"') { is_expected.to be == 'hard' }

          if e == 'notaccept'
            q = cn.soft_or_hard(e, '503 Not accept any email')
            it('503... returns "hard"') { expect(q).to be == 'hard' }

            r = cn.soft_or_hard(e, '409 Not accept any email')
            it('409... returns "soft"') { expect(r).to be == 'soft' }
          end
        end

        dependondsn.each do |e|
          q = cn.soft_or_hard(e, '503 Not accept any email')
          it('503... returns "hard"') { expect(q).to be == 'hard' }

          r = cn.soft_or_hard(e, '409 Not accept any email')
          it('409... returns "soft"') { expect(r).to be == 'soft' }

          s = cn.soft_or_hard(e, isnterrors.first)
          it('250... returns ""') { expect(s).to be == '' }
        end
      end

      context 'is not an error' do
        isntbounces.each do |e|
          v = cn.soft_or_hard(e)
          subject { v }
          it('returns String') { is_expected.to be_a String }
          it('returns ""') { is_expected.to be_empty }
        end
      end
    end

    context 'wrong number of arguments' do
      it 'raises ArgumentError' do
        expect { cn.soft_or_hard(nil, nil, nil) }.to raise_error(ArgumentError)
      end
    end
  end

end

