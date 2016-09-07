# coding: utf-8
require 'spec_helper'
require 'sisimai/mime'

describe Sisimai::MIME do
  cn = Sisimai::MIME
  p1 = 'ASCII TEXT'
  p2 = '白猫にゃんこ'
  p3 = 'ニュースレター'
  b2 = '=?utf-8?B?55m954yr44Gr44KD44KT44GT?='
  q3 = '=?utf-8?Q?=E3=83=8B=E3=83=A5=E3=83=BC=E3=82=B9=E3=83=AC=E3=82=BF=E3=83=BC?='

  describe '.is_mimeencoded' do
    context 'MIME encoded text' do
      it('returns true') { expect(cn.is_mimeencoded(b2)).to be true }
      it('returns true') { expect(cn.is_mimeencoded(q3)).to be true }
    end

    context 'is not MIME encoded' do
      it('returns false') { expect(cn.is_mimeencoded(p1)).to be false }
      it('returns false') { expect(cn.is_mimeencoded(p2)).to be false }
      it('returns false') { expect(cn.is_mimeencoded(p3)).to be false }
    end

    context 'wrong number of arguments' do
      it('raises ArgumentError') { expect { cn.is_mimeencoded(nil,nil) }.to raise_error(ArgumentError) }
    end
  end

  describe '.mimedecode' do
    context 'MIME encoded text' do
      v2 = cn.mimedecode([b2])
      it('returns String') { expect(v2).to be_a String }
      it('returns ' + p2)  { expect(v2).to be == p2 }

      v3 = cn.mimedecode([q3])
      it('returns String') { expect(v3).to be_a String }
      it('returns ' + p3)  { expect(v3).to be == p3 }

      # MIME-Encoded text in multiple lines
      p4 = '何でも薄暗いじめじめした所でニャーニャー泣いていた事だけは記憶している。'
      b4 = [
        '=?utf-8?B?5L2V44Gn44KC6JaE5pqX44GE44GY44KB44GY44KB44GX44Gf5omA?=',
        '=?utf-8?B?44Gn44OL44Oj44O844OL44Oj44O85rOj44GE44Gm44GE44Gf5LqL?=',
        '=?utf-8?B?44Gg44GR44Gv6KiY5oa244GX44Gm44GE44KL44CC?=',
      ]
      v4 = cn.mimedecode(b4)
      it('returns String') { expect(v4).to be_a String }
      it('returns ' + v4)  { expect(v4).to be == p4 }

      # Other encodings
      b5 = [
        '=?Shift_JIS?B?keWK24+8jeKJriAxMJackGyCyYKolIOVqIyUscDZDQo=?=',
        '=?ISO-2022-JP?B?Ym91bmNlSGFtbWVyGyRCJE41IUc9TVdLPhsoQg==?=',
      ]
      b5.each do |e|
        v5 = cn.mimedecode([e])
        it('returns String') { expect(v5).to be_a String }
        it('returns ' + v5 ) { expect(v5.chomp.size).to be > 0 }
      end
    end

    context 'wrong number of arguments' do
      it('raises ArgumentError') { expect { cn.mimedecode(nil,nil) }.to raise_error(ArgumentError) }
    end
  end

  # Base64, Quoted-Printable
  describe '.qprintd' do
    h7 = { 'content-type' => 'multipart/report; report-type=delivery-status; boundary="b0Nvs+XKfKLLRaP/Qo8jZhQPoiqeWi3KWPXMgw=="' }
    q7 = '
--b0Nvs+XKfKLLRaP/Qo8jZhQPoiqeWi3KWPXMgw==
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: quoted-printable

This is the mail delivery agent at messagelabs.com.

I was unable to deliver your message to the following addresses:

maria@dest.example.net

Reason: 550 maria@dest.example.net... No such user

The message subject was: Re: BOAS FESTAS!
The message date was: Tue, 23 Dec 2014 20:39:24 +0000
The message identifier was: DB/3F-17375-60D39495
The message reference was: server-5.tower-143.messagelabs.com!1419367172!32=
691968!1

Please do not reply to this email as it is sent from an unattended mailbox.
Please visit www.messagelabs.com/support for more details
about this error message and instructions to resolve this issue.


--b0Nvs+XKfKLLRaP/Qo8jZhQPoiqeWi3KWPXMgw==
Content-Type: message/delivery-status

Reporting-MTA: dns; server-15.bemta-3.messagelabs.com
Arrival-Date: Tue, 23 Dec 2014 20:39:34 +0000

    ';
    
    context 'Quoted-Printable string' do
      it('returns "Neko"') { expect(cn.qprintd('=4e=65=6b=6f')).to be == 'Neko' }
      d7 = cn.qprintd(q7, h7)
      it('returns String') { expect(d7).to be_a String }
      it('returns String') { expect(q7.size).to be > d7.size }
      it('includes boundary') { expect(d7).to match(%r|[-][-]b0Nvs[+]XKfKLLRaP/Qo8jZhQPoiqeWi3KWPXMgw==|m) }
      it('does not match 32=') { expect(d7).not_to match(/32=$/m) }
    end
    context 'wrong number of arguments' do
      it('raises ArgumentError') { expect { cn.qprintd(nil,nil,nil) }.to raise_error(ArgumentError) }
    end
  end

  describe '.base64d' do
    context 'Base64 string' do
      b6 = '44Gr44KD44O844KT'
      p6 = 'にゃーん'
      it('returns ' + p6) { expect(cn.base64d(b6)).to be == p6 }
    end
    context 'wrong number of arguments' do
      it('raises ArgumentError') { expect { cn.base64d(nil,nil) }.to raise_error(ArgumentError) }
    end
  end

  describe '.boundary' do
    context 'valid boundary string' do
      x1 = 'Content-Type: multipart/mixed; boundary=Apple-Mail-1-526612466'
      x2 = 'Apple-Mail-1-526612466'
      it('returns ' + x2) { expect(cn.boundary(x1)).to be == x2 }
      it('returns --' + x2) { expect(cn.boundary(x1,0)).to be == '--' + x2 }
      it('returns --' + x2 + '--') { expect(cn.boundary(x1,1)).to be == '--' + x2 + '--' }
      it('returns --' + x2 + '--') { expect(cn.boundary(x1,2)).to be == '--' + x2 + '--' }
    end

    context 'wrong number of arguments' do
      it('raises ArgumentError') { expect { cn.boundary(nil,nil,nil) }.to raise_error(ArgumentError) }
    end
  end
end
