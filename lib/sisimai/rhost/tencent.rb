module Sisimai
  module Rhost
    # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Fact object as an argument
    # of get() method when the value of "rhost" of the object is "mx*.qq.com". This class is called
    # only Sisimai::Fact class.
    module Tencent
      class << self
        MessagesOf = {
          'authfailure' => [
            'spf check failed',         # https://service.mail.qq.com/detail/122/72
            'dmarc check failed',
          ],
          'blocked' => [
            'suspected bounce attacks', # https://service.mail.qq.com/detail/122/57
            'suspected spam ip',        # https://service.mail.qq.com/detail/122/66
            'connection denied',        # https://service.mail.qq.com/detail/122/170
          ],
          'mesgtoobig' => [
            'message too large',        # https://service.mail.qq.com/detail/122/168
          ],
          'rejected' => [
            'suspected spam',                   # https://service.mail.qq.com/detail/122/71
            'mail is rejected by recipients',   # https://service.mail.qq.com/detail/122/92
          ],
          'spandetected' => [
            'spam is embedded in the email',    # https://service.mail.qq.com/detail/122/59
            'mail content denied',              # https://service.mail.qq.com/detail/122/171
          ],
          'speeding' => [
            'mailbox unavailable or access denined', # https://service.mail.qq.com/detail/122/166
          ],
          'suspend' => [
            'is a deactivated mailbox', # http://service.mail.qq.com/cgi-bin/help?subtype=1&&id=20022&&no=1000742
          ],
          'syntaxerror' => [
            'bad address syntax', # https://service.mail.qq.com/detail/122/167
          ],
          'toomanyconn' => [
            'ip frequency limited',         # https://service.mail.qq.com/detail/122/172
            'domain frequency limited',     # https://service.mail.qq.com/detail/122/173
            'sender frequency limited',     # https://service.mail.qq.com/detail/122/174
            'connection frequency limited', # https://service.mail.qq.com/detail/122/175
          ],
          'userunknown' => [
            'mailbox not found',  # https://service.mail.qq.com/detail/122/169
          ],
        }.freeze

        # Detect bounce reason from Tencent QQ
        # @param    [Sisimai::Fact] argvs   Parsed email object
        # @return   [String]                The bounce reason at Tencent QQ
        def get(argvs)
          issuedcode = argvs['diagnosticcode'].downcase
          reasontext = ''

          MessagesOf.each_key do |e|
            MessagesOf[e].each do |f|
              next unless issuedcode.include?(f)
              reasontext = e
              break
            end
            break if reasontext.size > 0
          end
          return reasontext
        end

      end
    end
  end
end

