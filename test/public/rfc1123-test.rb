require 'minitest/autorun'
require 'sisimai/rfc1123'

class RFC1123Test < Minitest::Test
  Methods = { class: %w[is_internethost] }

  Hostnames0 = [
    '',
    '127.0.0.1',
    'cat',
    'neko',
    'nyaan.22',
    'mx0.example.22',
    'mx0.example.jp-',
    'mx--0.example.jp',
    'mx..0.example.jp',
    'mx0.example.jp/neko',
  ]
  Hostnames1 = [
    'mx1.example.jp',
    'mx1.example.jp.',
    'a.jp',
    'localhost',
    'localhost6',
  ]
  IP46Domain = [
      ['', false],
      ['<neko@example.jp>', false],
      ['<neko@[IPv4:192.0.2.25]>', true],
      ['neko@[IPv4:192.0.2.25]', true],
      ['neko@[Neko:192.0.2.25]', false],
      ['neko@[IPv6:192.0.2.25]', false],
      ['neko@[IPv6:2001:DB8::1]', true],
      ['neko@[IPv5:2001:DB8::1]', false],
      ['<neko@[IPv6:2001:DB8::1]>', true],
      ['neko@[IPv6:2001:0DB8:0000:0000:0000:0000:0000:0001]', true],
      ['<neko@[IPv6:2001:0DB8:0000:0000:0000:0000:0000:0001]>', true],
  ]
  ServerSaid = [
    '<neko@example.jp>: host neko.example.jp[192.0.2.2] said: 550 5.7.1 This message was not accepted due to domain (libsisimai.org) owner DMARC policy',
    'neko.example.jp[192.0.2.232]: server refused to talk to me: 421 Service not available, closing transmission channel',
    '... while talking to neko.example.jp.: <<< 554 neko.example.jp ESMTP not accepting connections',
    'host neko.example.jp [192.0.2.222]: 500 Line limit exceeded',
    'Google tried to deliver your message, but it was rejected by the server for the recipient domain nyaan.jp by neko.example.jp. [192.0.2.2].',
    'Delivery failed for the following reason: Server neko.example.jp[192.0.2.222] failed with: 550 <kijitora@example.jp> No such user here',
    'Remote system: dns;neko.example.jp (TCP|17.111.174.65|48044|192.0.2.225|25) (neko.example.jp ESMTP SENDMAIL-VM)',
    'SMTP Server <neko.example.jp> rejected recipient <cat@libsisimai.org> (Error following RCPT command). It responded as follows: [550 5.1.1 User unknown]',
    'Reporting-MTA:      <neko.example.jp>',
    'cat@example.jp:000000:<cat@example.jp> : 192.0.2.250 : neko.example.jp:[192.0.2.153] : 550 5.1.1 <cat@example.jp>... User Unknown  in RCPT TO',
    'Generating server: neko.example.jp',
    'Server di generazione: neko.example.jp',
    'Serveur de génération : neko.example.jp',
    'Genererande server: neko.example.jp',
    'neko.example.jp [192.0.2.25] did not like our RCPT TO: 550 5.1.1 <cat@example.jp>: Recipient address rejected: User unknown',
    'neko.example.jp [192.0.2.79] did not like our final DATA: 554 5.7.9 Message not accepted for policy reasons',
  ]

  def test_is_internethost
    Hostnames0.each do |e|
      # Invalid hostnames
      assert_equal false, Sisimai::RFC1123.is_internethost(e)
    end

    Hostnames1.each do |e|
      # Valid hostnames
      assert_equal true,  Sisimai::RFC1123.is_internethost(e)
    end

    ce = assert_raises ArgumentError do
      Sisimai::RFC1123.is_internethost(nil, nil)
    end
  end

  def test_is_domainliteral
    IP46Domain.each do |e|
      # IPv4 or IPv6
      assert_equal e[1], Sisimai::RFC1123.is_domainliteral(e[0])
    end

    ce = assert_raises ArgumentError do
      Sisimai::RFC1123.is_domainliteral(nil, nil)
    end
  end

  def test_find
    ServerSaid.each do |e|
      # find() returns "neko.example.jp"
      assert_equal "neko.example.jp", Sisimai::RFC1123.find(e)
    end

    ce = assert_raises ArgumentError do
      Sisimai::RFC1123.find(nil, nil)
    end
  end

end

