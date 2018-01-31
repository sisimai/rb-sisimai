module Sisimai
  module Reason
    # Sisimai::Reason::TooManyConn checks the bounce reason is "toomanyconn" or
    # not. This class is called only Sisimai::Reason class.
    #
    # This is the error that SMTP connection was rejected temporarily due to too
    # many concurrency connections to the remote server. This reason has added
    # in Sisimai 4.1.26 and does not exist in any version of bounceHammer.
    #
    #   <kijitora@example.ne.jp>: host mx02.example.ne.jp[192.0.1.20] said:
    #     452 4.3.2 Connection rate limit exceeded. (in reply to MAIL FROM command)
    module TooManyConn
      # Imported from p5-Sisimail/lib/Sisimai/Reason/TooManyConn.pm
      class << self
        def text; return 'toomanyconn'; end
        def description; return 'SMTP connection rejected temporarily due to too many concurrency connections to the remote host'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          regex = %r{(?>
             All[ ]available[ ]IPs[ ]are[ ]at[ ]maximum[ ]connection[ ]limit    # SendGrid
            |connection[ ]rate[ ]limit[ ]exceeded
            |domain[ ].+[ ]has[ ]exceeded[ ]the[ ]max[ ]emails[ ]per[ ]hour[ ].+[ ]allowed
            |no[ ]IPs[ ]available[ ][-][ ].+[ ]exceeds[ ]per[-]domain[ ]connection[ ]limit[ ]for
            |Throttling[ ]failure:[ ](?:
               Daily[ ]message[ ]quota[ ]exceeded
              |Maximum[ ]sending[ ]rate[ ]exceeded
              )
            |Too[ ]many[ ](?:
               connections
              |connections[ ]from[ ]your[ ]host[.]    # Microsoft
              |concurrent[ ]SMTP[ ]connections        # Microsoft
              |errors[ ]from[ ]your[ ]IP              # Free.fr
              |SMTP[ ]sessions[ ]for[ ]this[ ]host    # Sendmail(daemon.c)
              )
            |Trop[ ]de[ ]connexions,[ ].+[A-Z]{3}.+104
            |We[ ]have[ ]already[ ]made[ ]numerous[ ]attempts[ ]to[ ]deliver[ ]this[ ]message
            )
          }ix

          return true if argv1 =~ regex
          return false
        end

        # Rejected by domain or address filter ?
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: is filtered
        #                                   false: is not filtered
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return nil unless argvs
          return nil unless argvs.is_a? Sisimai::Data
          return true if argvs.reason == 'toomanyconn'

          require 'sisimai/smtp/status'
          return true if Sisimai::SMTP::Status.name(argvs.deliverystatus) == 'toomanyconn'
          return true if match(argvs.diagnosticcode)
          return false
        end

      end
    end
  end
end



