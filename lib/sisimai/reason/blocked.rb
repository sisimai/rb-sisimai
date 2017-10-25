module Sisimai
  module Reason
    # Sisimai::Reason::Blocked checks the bounce reason is "blocked" or not.
    # This class is called only Sisimai::Reason class.
    #
    # This is the error that SMTP connection was rejected due to a client IP address
    # or a hostname, or the parameter of "HELO/EHLO" command. This reason has added
    # in Sisimai 4.0.0 and does not exist in any version of bounceHammer.
    module Blocked
      # Imported from p5-Sisimail/lib/Sisimai/Reason/Blocked.pm
      class << self
        def text; return 'blocked'; end
        def description
          return 'Email rejected due to client IP address or a hostname'
        end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          regex = %r{(?>
             access[ ]denied[.][ ]IP[ ]name[ ]lookup[ ]failed
            |access[ ]from[ ]ip[ ]address[ ].+[ ]blocked
            |blacklisted[ ]by
            |Blocked[ ]-[ ]see[ ]https://support[.]proofpoint[.]com/dnsbl-lookup[.]cgi[?]ip=.+
            |can[']t[ ]determine[ ]Purported[ ]Responsible[ ]Address
            |cannot[ ]resolve[ ]your[ ]address
            |client[ ]host[ ].+[ ]blocked[ ]using
            |client[ ]host[ ]rejected:[ ](?:
               may[ ]not[ ]be[ ]mail[ ]exchanger
              |cannot[ ]find[ ]your[ ]hostname    # Yahoo!
              |was[ ]not[ ]authenticated          # Microsoft
              )
            |confirm[ ]this[ ]mail[ ]server
            |connection[ ](?:
              dropped
             |refused[ ]by
             |reset[ ]by[ ]peer
             |was[ ]dropped[ ]by[ ]remote[ ]host
             )
            |domain[ ]does[ ]not[ ]exist:
            |domain[ ].+[ ]mismatches[ ]client[ ]ip
            |dns[ ]lookup[ ]failure:[ ].+[ ]try[ ]again[ ]later
            |DNSBL:ATTRBL
            |Go[ ]away
            |hosts[ ]with[ ]dynamic[ ]ip
            |IP[ ]\d{1,3}[.]\d{1,3}[.]\d{1,3}[.]\d{1,3}[ ]is[ ]blocked[ ]by[ ]EarthLink # Earthlink
            |IP[/]domain[ ]reputation[ ]problems
            |is[ ]not[ ]allowed[ ]to[ ]send[ ]mail[ ]from
            |LPN007_510 # laposte.net
            |mail[ ]server[ ]at[ ].+[ ]is[ ]blocked
            |Messages[ ]from[ ].+[ ]temporarily[ ]deferred[ ]due[ ]to[ ]user[ ]complaints   # Yahoo!
            |ofr_506  # orange.fr
            |no[ ]access[ ]from[ ]mail[ ]server
            |Not[ ]currently[ ]accepting[ ]mail[ ]from[ ]your[ ]ip  # Microsoft
            |Please[ ]get[ ]a[ ]custom[ ]reverse[ ]DNS[ ]name[ ]from[ ]your[ ]ISP[ ]for[ ]your[ ]host
            |please[ ]use[ ]the[ ]smtp[ ]server[ ]of[ ]your[ ]ISP
            |Rejecting[ ]open[ ]proxy   # Sendmail(srvrsmtp.c)
            |sorry,[ ](?:
               that[ ]domain[ ]isn'?t[ ]in[ ]my[ ]list[ ]of[ ]allowed[ ]rcpthosts
              |your[ ]remotehost[ ]looks[ ]suspiciously[ ]like[ ]spammer
              )
            |SPF[ ]record
            |the[ ](?:email|domain|ip).+[ ]is[ ]blacklisted
            |unresolvable[ ]relay[ ]host[ ]name
            |your[ ](?:
               network[ ]is[ ]temporary[ ]blacklisted
              |server[ ]requires[ ]confirmation
              )
            |was[ ]blocked[ ]by[ ].+
            |we[ ]do[ ]not[ ]accept[ ]mail[ ]from[ ](?: # @mail.ru
               hosts[ ]with[ ]dynamic[ ]IP[ ]or[ ]generic[ ]dns[ ]PTR-records
              |dynamic[ ]ips
              )
            |http://www[.]spamcop[.]net/bl[.]
            )
          }xi

          return true if argv1 =~ regex
          return false
        end

        # Blocked due to client IP address or hostname
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: is blocked
        #                                   false: is not blocked by the client
        # @see      http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return nil unless argvs
          return nil unless argvs.is_a? Sisimai::Data
          return true if argvs.reason == Sisimai::Reason::Blocked.text

          require 'sisimai/smtp/status'
          diagnostic = argvs.diagnosticcode || ''
          statuscode = argvs.deliverystatus || ''
          tempreason = Sisimai::SMTP::Status.name(statuscode)
          reasontext = Sisimai::Reason::Blocked.text
          v = false

          if tempreason == reasontext
            # Delivery status code points "blocked".
            v = true
          else
            # Matched with a pattern in this class
            v = true if Sisimai::Reason::Blocked.match(diagnostic)
          end

          return v
        end

      end
    end
  end
end
