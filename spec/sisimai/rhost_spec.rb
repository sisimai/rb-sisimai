require 'spec_helper'
require 'sisimai/rhost'

describe Sisimai::Rhost do
  cn = Sisimai::Rhost
  describe '.match' do
    context 'valid argument string' do
      v = [
        'aspmx.l.google.com',
        'gmail-smtp-in.l.google.com',
        'neko.protection.outlook.com',
        'smtp.secureserver.net',
        'mailstore1.secureserver.net',
        'smtpz4.laposte.net',
        'smtp-in.orange.fr',
        'mx2.qq.com',
        'mx3.email.ua',
      ]
      v.each do |e|
        context "(#{e})" do
          it('returns true') { expect(cn.match(e)).to be true }
        end
      end
      context 'example.jp' do
        it('returns false') { expect(cn.match('example.jp')).to be false }
      end
    end

    context 'wrong number of arguments' do
      context '(nil,nil)' do
        it('raises ArgumentError') { expect { cn.match(nil, nil) }.to raise_error(ArgumentError) }
      end
    end
  end

  describe 'get' do
    require 'sisimai'
    require 'sisimai/reason'
    r = Sisimai::Reason.index.each { |p| p.downcase! }
    Dir.glob('./set-of-emails/maildir/bsd/rhost-*.eml').each do |e|
      v = Sisimai.make(e)
      context 'Sisimai::Data' do
        it('has valid reason value') { expect(v[0].reason.size).to be > 0 }
        it('has valid rhost value')  { expect(v[0].rhost.size).to be > 0 }
      end
    end
  end
end

