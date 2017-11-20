module Sisimai
  module Reason
    # Sisimai::Reason::Rejected checks the bounce reason is "rejected" or not.
    # This class is called only Sisimai::Reason class.
    #
    # This is the error that a connection to destination server was rejected by
    # a sender's email address (envelope from). Sisimai set "rejected" to the
    # reason of email bounce if the value of Status: field in a bounce email is
    # "5.1.8" or the connection has been rejected due to the argument of SMTP
    # MAIL command.
    #
    #   <kijitora@example.org>:
    #   Connected to 192.0.2.225 but sender was rejected.
    #   Remote host said: 550 5.7.1 <root@nijo.example.jp>... Access denied
    module Rejected
      # Imported from p5-Sisimail/lib/Sisimai/Reason/Rejected.pm
      class << self
        def text; return 'rejected'; end
        def description
          return "Email rejected due to a sender's email address (envelope from)"
        end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          isnot = %r/recipient[ ]address[ ]rejected/xi
          regex = %r{(?>
             [<][>][ ]invalid[ ]sender
            |address[ ]rejected
            |Administrative[ ]prohibition
            |batv[ ](?:
               failed[ ]to[ ]verify   # SoniWall
              |validation[ ]failure   # SoniWall
              )
            |backscatter[ ]protection[ ]detected[ ]an[ ]invalid[ ]or[ ]expired[ ]email[ ]address    # MDaemon
            |bogus[ ]mail[ ]from        # IMail - block empty sender
            |Connections[ ]not[ ]accepted[ ]from[ ]servers[ ]without[ ]a[ ]valid[ ]sender[ ]domain
            |denied[ ]\[bouncedeny\]    # McAfee
            |does[ ]not[ ]exist[ ]E2110
            |domain[ ]of[ ]sender[ ]address[ ].+[ ]does[ ]not[ ]exist
            |Emetteur[ ]invalide.+[A-Z]{3}.+(?:403|405|415)
            |empty[ ]envelope[ ]senders[ ]not[ ]allowed
            |error:[ ]no[ ]third-party[ ]dsns               # SpamWall - block empty sender
            |From:[ ]Domain[ ]is[ ]invalid[.][ ]Please[ ]provide[ ]a[ ]valid[ ]From:
            |fully[ ]qualified[ ]email[ ]address[ ]required # McAfee
            |invalid[ ]domain,[ ]see[ ][<]url:.+[>]
            |Mail[ ]from[ ]not[ ]owned[ ]by[ ]user.+[A-Z]{3}.+421
            |Message[ ]rejected:[ ]Email[ ]address[ ]is[ ]not[ ]verified
            |mx[ ]records[ ]for[ ].+[ ]violate[ ]section[ ].+
            |Null[ ]Sender[ ]is[ ]not[ ]allowed
            |recipient[ ]not[ ]accepted[.][ ][(]batv:[ ]no[ ]tag
            |returned[ ]mail[ ]not[ ]accepted[ ]here
            |rfc[ ]1035[ ]violation:[ ]recursive[ ]cname[ ]records[ ]for
            |rule[ ]imposed[ ]mailbox[ ]access[ ]for        # MailMarshal
            |sender[ ](?:
               verify[ ]failed        # Exim callout
              |not[ ]pre[-]approved
              |rejected
              |domain[ ]is[ ]empty
              )
            |syntax[ ]error:[ ]empty[ ]email[ ]address
            |the[ ]message[ ]has[ ]been[ ]rejected[ ]by[ ]batv[ ]defense
            |transaction[ ]failed[ ]unsigned[ ]dsn[ ]for
            |Unroutable[ ]sender[ ]address
            |you[ ]are[ ]sending[ ]to[/]from[ ]an[ ]address[ ]that[ ]has[ ]been[ ]blacklisted
            )
          }ix

          return false if argv1 =~ isnot
          return true  if argv1 =~ regex
          return false
        end

        # Rejected by the envelope sender address or not
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: is rejected
        #                                   false: is not rejected by the sender
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return nil unless argvs
          return nil unless argvs.is_a? Sisimai::Data

          require 'sisimai/smtp/status'
          statuscode = argvs.deliverystatus || ''
          reasontext = Sisimai::Reason::Rejected.text

          return true if argvs.reason == reasontext

          tempreason = Sisimai::SMTP::Status.name(statuscode)
          tempreason = 'undefined' if tempreason.empty?
          diagnostic = argvs.diagnosticcode || ''
          v = false

          if tempreason == reasontext
            # Delivery status code points "rejected".
            v = true
          else
            # Check the value of Diagnosic-Code: header with patterns
            if argvs.smtpcommand == 'MAIL'
              # The session was rejected at 'MAIL FROM' command
              v = true if Sisimai::Reason::Rejected.match(diagnostic)

            elsif argvs.smtpcommand == 'DATA'
              # The session was rejected at 'DATA' command
              if tempreason != 'userunknown'
                # Except "userunknown"
                v = true if Sisimai::Reason::Rejected.match(diagnostic)
              end
            else
              if tempreason == 'undefined' || tempreason == 'onhold'
                # Try to match with message patterns when the temporary reason
                # is "onhold" or "undefined"
                v = true if Sisimai::Reason::Rejected.match(diagnostic)
              end
            end
          end

          return v
        end

      end
    end
  end
end



