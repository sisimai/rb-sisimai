module Sisimai
  module Rhost
    # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Fact object as an argument
    # of find() method when the value of "rhost" of the object is "mx*.qq.com". This class is called
    # only Sisimai::Fact class.
    module Tencent
      class << self
        require 'sisimai/eb'
        MessagesOf = {
          Sisimai::Eb::ReAUTH => [
            'spf check failed',         # https://service.mail.qq.com/detail/122/72
            'dmarc check failed',
          ],
          Sisimai::Eb::ReBLOC => [
            'suspected bounce attacks', # https://service.mail.qq.com/detail/122/57
            'suspected spam ip',        # https://service.mail.qq.com/detail/122/66
            'connection denied',        # https://service.mail.qq.com/detail/122/170
          ],
          Sisimai::Eb::ReSIZE => [
            'message too large',        # https://service.mail.qq.com/detail/122/168
          ],
          Sisimai::Eb::ReRATE => [
            'mailbox unavailable or access denined',      # https://service.mail.qq.com/detail/122/166
            'ip frequency limited',                       # https://service.mail.qq.com/detail/122/172
            'domain frequency limited',                   # https://service.mail.qq.com/detail/122/173
            'sender frequency limited',                   # https://service.mail.qq.com/detail/122/174
            'connection frequency limited',               # https://service.mail.qq.com/detail/122/175
            "frequency of receiving messages is limited", # https://service.mail.qq.com/detail/122/1011
          ],
          Sisimai::Eb::ReFROM => [
            'suspected spam',                   # https://service.mail.qq.com/detail/122/71
            'mail is rejected by recipients',   # https://service.mail.qq.com/detail/122/92
          ],
          Sisimai::Eb::ReSPAM => [
            'spam is embedded in the email',    # https://service.mail.qq.com/detail/122/59
            'mail content denied',              # https://service.mail.qq.com/detail/122/171
          ],
          Sisimai::Eb::ReQUIT => [
            'is a deactivated mailbox', # http://service.mail.qq.com/cgi-bin/help?subtype=1&&id=20022&&no=1000742
          ],
          Sisimai::Eb::ReCOMM => [
            'bad address syntax', # https://service.mail.qq.com/detail/122/167
          ],
          Sisimai::Eb::ReUSER => [
            'mailbox not found',  # https://service.mail.qq.com/detail/122/169
          ],
        }.freeze

        # Detect bounce reason from Tencent QQ
        # @param    [Sisimai::Fact] argvs   Decoded email object
        # @return   [String]                The bounce reason at Tencent QQ
        def find(argvs)
          return argvs['reason'] if argvs['reason'].empty? == false
          issuedcode = argvs['diagnosticcode'].downcase
          reasontext = ''

          MessagesOf.each_key do |e|
            MessagesOf[e].each do |f|
              next if issuedcode.include?(f) == false
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

