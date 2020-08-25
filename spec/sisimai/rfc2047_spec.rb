# coding: utf-8
require 'spec_helper'
require 'sisimai/rfc2047'

describe Sisimai::RFC2047 do
  cn = Sisimai::RFC2047
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

    context 'Irregular MIME encoded test' do
      # Irregular MIME encoded strings
      bE = [
        '[NEKO] =?UTF-8?B?44OL44Oj44O844Oz?=',
        '=?UTF-8?B?44OL44Oj44O844Oz?= [NYAAN]',
        '[NEKO] =?UTF-8?B?44OL44Oj44O844Oz?= [NYAAN]'
      ]
      bE.each do |e|
        vE = cn.mimedecode([e])
        it('returns true') { expect(cn.is_mimeencoded(e)).to be true }
        it('matches /ニャーン/') { expect(vE).to match %r/ニャーン/ }
      end
    end

    context 'wrong number of arguments' do
      it('raises ArgumentError') { expect { cn.mimedecode(nil,nil) }.to raise_error(ArgumentError) }
    end
  end

  # Base64, Quoted-Printable
  describe '.qprintd' do
    q6 = 'I will be traveling for work on July 10-31.  During that time I will have i=
ntermittent access to email and phone, and I will respond to your message a=
s promptly as possible.

Please contact our Client Service Support Team (information below) if you n=
eed immediate assistance on regular account matters, or contact my colleagu=
e Neko Nyaan (neko@example.org; +0-000-000-0000) for all other needs.
'
    context 'Quoted-Printable string' do
      it('returns "Neko"') { expect(cn.qprintd('=4e=65=6b=6f')).to be == 'Neko' }
      v6 = cn.qprintd(q6)
      it('returns String') { expect(v6).to be_a ::String }
      it('returns String') { expect(q6.size).to be > v6.size }
      it('does not match a=') { expect(v6).not_to match(/a=$/m) }
    end

    context 'wrong number of arguments' do
      it('raises ArgumentError') { expect { cn.qprintd(nil,nil) }.to raise_error(ArgumentError) }
    end
  end

  describe '.base64d' do
    context 'Base64 string' do
      b8 = '44Gr44KD44O844KT'
      p8 = 'にゃーん'
      it('returns ' + p8) { expect(cn.base64d(b8)).to be == p8 }
    end
    context 'wrong number of arguments' do
      it('raises ArgumentError') { expect { cn.base64d(nil,nil) }.to raise_error(ArgumentError) }
    end
  end

  describe '.ctvalue' do
    context 'valid value of Content-Type header' do
      x1 = 'multipart/mixed; boundary=nekochan; charset=utf8'
      it('returns multipart/mixed') { expect(cn.ctvalue(x1)).to be == 'multipart/mixed' }
      it('returns nekochan') { expect(cn.ctvalue(x1, 'boundary')).to be == 'nekochan' }
      it('returns utf8') { expect(cn.ctvalue(x1, 'charset')).to be == 'utf8' }
      it('returns ""') { expect(cn.ctvalue(x1, 'nyaan')).to be == '' }
      it('returns nil') { expect(cn.ctvalue("")).to be == nil }
    end

    context 'wrong number of arguments' do
      it('raises ArgumentError') { expect { cn.ctvalue(nil,nil,nil) }.to raise_error(ArgumentError) }
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

  describe '.haircut' do
    v1 = 'Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: base64
Content-Description: nekochan

c2lyb25la28K'
    r1 = cn.haircut(v1)
    it('returns Arry') { expect(r1).to be_a Array }
    it('has 3 elements') { expect(r1.size).to be == 3 }
    it('is a text/plain in r[0]') { expect(r1[0]).to match(/plain; charset/) }
    it('is a base64 in r1[1]') { expect(r1[1]).to match(/base64/) }
    it('has a string in r1[2]') { expect(r1[2]).to be_a ::String }

    r2 = cn.haircut(v1, true)
    it('returns Arry') { expect(r2).to be_a Array }
    it('has 2 elements') { expect(r2.size).to be == 2 }
    it('is a text/plain in r2[0]') { expect(r2[0]).to match(/plain; charset/) }
    it('is a base64 in r2[1]') { expect(r2[1]).to match(/base64/) }
  end

  describe '.levelout' do
    ct = 'multipart/mixed; boundary="b0Nvs+XKfKLLRaP/Qo8jZhQPoiqeWi3KWPXMgw=="';
    mp = '
--b0Nvs+XKfKLLRaP/Qo8jZhQPoiqeWi3KWPXMgw==
Content-Description: "error-message"
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
    
    v1 = cn.levelout(ct, mp)
    it('returns an Array') { expect(v1).to be_a Array }
    it('has 2 elements') { expect(v1.size).to be == 2 }

    context 'wrong number of arguments' do
      it('raises ArgumentError') { expect { cn.levelout(nil,nil,nil) }.to raise_error(ArgumentError) }
    end

  end

  describe '.makeflat' do
    h9 = { 'content-type' => 'multipart/report; report-type=delivery-status; boundary="NekoNyaan--------1"' }
    p9 = '--NekoNyaan--------1
Content-Type: multipart/related; boundary="NekoNyaan--------2"

--NekoNyaan--------2
Content-Type: multipart/alternative; boundary="NekoNyaan--------3"

--NekoNyaan--------3
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: base64

c2lyb25la28K

--NekoNyaan--------3
Content-Type: text/html; charset="UTF-8"
Content-Transfer-Encoding: base64

PGh0bWw+CjxoZWFkPgogICAgPHRpdGxlPk5la28gTnlhYW48L3RpdGxlPgo8L2hl
YWQ+Cjxib2R5PgogICAgPGgxPk5la28gTnlhYW48L2gxPgo8L2JvZHk+CjwvaHRt
bD4K

--NekoNyaan--------2
Content-Type: image/jpg

/9j/4AAQSkZJRgABAQEBLAEsAAD/7VaWUGhvdG9zaG9wIDMuMAA4QklNBAwAAAAA
Vk4AAAABAAAArwAAAQAAAAIQAAIQAAAAVjIAGAAB/9j/7gAOQWRvYmUAZAAAAAAB
/9sAhAAGBAQEBQQGBQUGCQYFBgkLCAYGCAsMCgoLCgoMEAwMDAwMDBAMDAwMDAwM
DAwMDAwMDAwMDAwMDAwMDAwMDAwMAQcHBw0MDRgQEBgUDg4OFBQODg4OFBEMDAwM
DBERDAwMDAwMEQwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAz/wAARCAEAAK8D
AREAAhEBAxEB/90ABAAW/8QBogAAAAcBAQEBAQAAAAAAAAAABAUDAgYBAAcICQoL

--NekoNyaan--------2
Content-Type: message/delivery-status

Reporting-MTA: dns; example.jp
Received-From-MTA: dns; neko.example.jp
Arrival-Date: Thu, 11 Oct 2018 23:34:45 +0900 (JST)

Final-Recipient: rfc822; kijitora@example.jp
Action: failed
Status: 5.1.1
Diagnostic-Code: User Unknown

--NekoNyaan--------2
Content-Type: message/rfc822

Received: ...

--NekoNyaan--------2--

    '
    context 'mutipart/report message body' do
      v9 = cn.makeflat(h9['content-type'], p9)
      it('returns String') { expect(v9).to be_a String }
      it('contain "text/plain part"') { expect(v9).to match(/sironeko/) }
      it('does not contain text/html part') { expect(v9).not_to match(/<html>/) }
      it('does not contain image/jpg part') { expect(v9).not_to match(/4AAQSkZJRgABAQEBLAEsAAD/) }
      it('contain "message/delivery-status part"') { expect(v9).to match(/kijitora[@]/) }
      it('contain "message/rfc822 part"') { expect(v9).to match(/Received:/) }
      it('returns Nil') { expect(cn.makeflat(nil,nil)).to be_nil }
    end

    context 'wrong number of arguments' do
      it('raises ArgumentError') { expect { cn.makeflat(nil,nil,nil) }.to raise_error(ArgumentError) }
    end
  end
end
