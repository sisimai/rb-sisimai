module Sisimai
  module Rhost
    # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Data
    # object as an argument of get() method when the value of "rhost" of the object
    # is "*.protection.outlook.com". This class is called only Sisimai::Data class.
    module ExchangeOnline
      class << self
        # Imported from p5-Sisimail/lib/Sisimai/Rhost/ExchangeOnline.pm

        # https://technet.microsoft.com/en-us/library/bb232118
        CodeTable = {
          %r/\A4[.]3[.]1\z/ => [
            {
              :reason => 'systemfull',
              :regexp => %r/Insufficient system resources/,
            },
          ],
          %r/\A4[.]3[.]2\z/ => [
            {
              :reason => 'notaccept',
              :regexp => %r/System not accepting network messages/,
            },
          ],
          %r/\A4[.]4[.][17]\z/ => [
            {
              :reason => 'expired',
              :regexp => %r/(?:Connection[ ]timed[ ]out|Message[ ]expired)/x,
            },
          ],
          %r/\A4[.]4[.]2\z/ => [
            {
              :reason => 'blocked',
              :regexp => %r/Connection dropped/,
            },
          ],
          %r/\A4[.]7[.]26\z/ => [
            {
              :reason => 'securityerror',
              :regexp => %r/Access denied, a message sent over IPv6 .+ must pass either SPF or DKIM validation, this message is not signed/,
            },
          ],
          %r/\A4[.]7[.][568]\d{2}\z/ => [
            {
              :reason => 'securityerror',
              :regexp => %r/Access denied, please try again later/,
            },
          ],
          %r/\A5[.]0[.]0\z/ => [
            {
              :reason => 'blocked',
              :regexp => %r|HELO / EHLO requires domain address|,
            },
          ],
          %r/\A5[.]1[.][07]\z/ => [
            {
              :reason => 'rejected',
              :regexp => %r/(?:Sender[ ]denied|Invalid[ ]address)/x,
            },
          ],
          %r/\A5[.]1[.][123]\z/ => [
            {
              :reason => 'userunknown',
              :regexp => %r{(?:
                 Bad[ ]destination[ ]mailbox[ ]address
                |Invalid[ ]X[.]400[ ]address
                |Invalid[ ]recipient[ ]address
                )
              }x,
            },
          ],
          %r/\A5[.]1[.]4\z/ => [
            {
              :reason => 'systemerror',
              :regexp => %r/Destination mailbox address ambiguous/,
            },
          ],
          %r/\A5[.]2[.]1\z/ => [
            {
              :reason => 'suspend',
              :regexp => %r/Mailbox cannot be accessed/,
            },
          ],
          %r/\A5[.]2[.]2\z/ => [
            {
              :reason => 'mailboxfull',
              :regexp => %r/Mailbox full/,
            },
          ],
          %r/\A5[.]2[.]3\z/ => [
            {
              :reason => 'exceedlimit',
              :regexp => %r/Message too large/,
            },
          ],
          %r/\A5[.]2[.]4\z/ => [
            {
              :reason => 'systemerror',
              :regexp => %r/Mailing list expansion problem/,
            },
          ],
          %r/\A5[.]3[.]3\z/ => [
            {
              :reason => 'systemfull',
              :regexp => %r/Unrecognized command/,
            },
          ],
          %r/\A5[.]3[.]4\z/ => [
            {
              :reason => 'mesgtoobig',
              :regexp => %r/Message too big for system/,
            },
          ],
          %r/\A5[.]3[.]5\z/ => [
            {
              :reason => 'systemerror',
              :regexp => %r/System incorrectly configured/,
            },
          ],
          %r/\A5[.]4[.]1\z/ => [
            {
              :reason => 'userunknown',
              :regexp => %r/Recipient address rejected: Access denied/,
            },
          ],
          %r/\A5[.]4[.][46]\z/ => [
            {
              :reason => 'networkerror',
              :regexp => %r/(?:Invalid[ ]arguments|Routing[ ]loop[ ]detected)/x,
            },
          ],
          %r/\A5[.]5[.]2\z/ => [
            {
              :reason => 'syntaxerror',
              :regexp => %r/Send hello first/,
            },
          ],
          %r/\A5[.]5[.]3\z/ => [
            {
              :reason => 'syntaxerror',
              :regexp => %r/Too many recipients/,
            },
          ],
          %r/\A5[.]5[.]4\z/ => [
            {
              :reason => 'filtered',
              :regexp => %r/Invalid domain name/,
            },
          ],
          %r/\A5[.]5[.]6\z/ => [
            {
              :reason => 'contenterror',
              :regexp => %r/Invalid message content/,
            },
          ],
          %r/\A5[.]7[.][13]\z/ => [
            {
              :reason => 'securityerror',
              :regexp => %r/(?:Delivery[ ]not[ ]authorized|Not[ ]Authorized)/x,
            },
          ],
          %r/\A5[.]7[.]1\z/ => [
            {
              :reason => 'securityerror',
              :regexp => %r/(?:Delivery[ ]not[ ]authorized|Client[ ]was[ ]not[ ]authenticated)/x,
            },
            {
              :reason => 'norelaying',
              :regexp => %r/Unable to relay/,
            },
          ],
          %r/\A5[.]7[.]25\z/ => [
            {
              :reason => 'securityerror',
              :regexp => %r/Access denied, the sending IPv6 address .+ must have a reverse DNS record/,
            },
          ],
          %r/\A5[.]7[.]50[1-3]\z/ => [
            {
              :reason => 'spamdetected',
              :regexp => %r/Access[ ]denied,[ ](?:spam[ ]abuse[ ]detected|banned[ ]sender)/x,
            },
          ],
          %r/\A5[.]7[.]50[457]\z/ => [
            {
              :reason => 'filtered',
              :regexp => %r{(?>
                 Recipient[ ]address[ ]rejected:[ ]Access[ ]denied
                |Access[ ]denied,[ ](?:banned[ ]recipient|rejected[ ]by[ ]recipient)
                )
              },
            },
          ],
          %r/\A5[.]7[.]506\z/ => [
            {
              :reason => 'blocked',
              :regexp => %r/Access Denied, Bad HELO/,
            },
          ],
          %r/\A5[.]7[.]508\z/ => [
            {
              :reason => 'toomanyconn',
              :regexp => %r/Access denied, .+ has exceeded permitted limits within .+ range/,
            },
          ],
          %r/\A5[.]7[.]509\z/ => [
            {
              :reason => 'securityerror',
              :regexp => %r/Access denied, sending domain .+ does not pass DMARC verification/,
            },
          ],
          %r/\A5[.]7[.]510\z/ => [
            {
              :reason => 'notaccept',
              :regexp => %r/Access denied, .+ does not accept email over IPv6/,
            },
          ],
          %r/\A5[.]7[.]511\z/ => [
            {
              :reason => 'blocked',
              :regexp => %r/Access denied, banned sender/,
            },
          ],
          %r/\A5[.]7[.]512\z/ => [
            {
              :reason => 'contenterror',
              :regexp => %r/Access denied, message must be RFC 5322 section 3[.]6[.]2 compliant/,
            },
          ],
          %r/\A5[.]7[.]6\d{2}\z/ => [
            {
              :reason => 'blocked',
              :regexp => %r/Access[ ]denied,[ ]banned[ ]sending[ ]IP[ ].+/,
            },
          ],
          %r/\A5[.]7[.]7\d{2}\z/ => [
            {
              :reason => 'toomanyconn',
              :regexp => %r/Access denied, tenant has exceeded threshold/,
            },
          ],
        }

        # Detect bounce reason from Exchange Online
        # @param    [Sisimai::Data] argvs   Parsed email object
        # @return   [String]                The bounce reason for Exchange Online
        def get(argvs)
          return nil unless argvs
          return nil unless argvs.is_a? Sisimai::Data
          return argvs.reason if argvs.reason.size > 0

          statuscode = argvs.deliverystatus
          statusmesg = argvs.diagnosticcode
          reasontext = ''

          CodeTable.each_key do |e|
            # Try to match with each regular expression of delivery status codes
            next unless statuscode =~ e
            CodeTable[e].each do |f|
              # Try to match with each regular expression of error messages
              next unless statusmesg =~ f[:regexp]
              reasontext = f[:reason]
              break
            end
          end

          return reasontext
        end

      end
    end
  end
end

