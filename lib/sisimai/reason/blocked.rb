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
            |all[ ]mail[ ]servers[ ]must[ ]have[ ]a[ ]PTR[ ]record[ ]with[ ]a[ ]valid[ ]Reverse[ ]DNS[ ]entry
            |Bad[ ]sender[ ]IP[ ]address
            |blacklisted[ ]by
            |(?:Blocked|Refused)[ ]-[ ]see[ ]https?://
            |can[']t[ ]determine[ ]Purported[ ]Responsible[ ]Address
            |cannot[ ](?:
               find[ ]your[ ]hostname
              |resolve[ ]your[ ]address
              )
            |client[ ]host[ ](?:
               .+[ ]blocked[ ]using
              |rejected:[ ](?:
                 Abus[ ]detecte[ ]GU_EIB_0[24]      # SFR
                |cannot[ ]find[ ]your[ ]hostname    # Yahoo!
                |may[ ]not[ ]be[ ]mail[ ]exchanger
                |was[ ]not[ ]authenticated          # Microsoft
                )
              )
            |confirm[ ]this[ ]mail[ ]server
            |connection[ ](?:
               dropped
              |refused[ ]by
              |reset[ ]by[ ]peer
              |was[ ]dropped[ ]by[ ]remote[ ]host
              )
            |Connections[ ](?:
               not[ ]accepted[ ]from[ ]IP[ ]addresses[ ]on[ ]Spamhaus[ ]XBL
              |will[ ]not[ ]be[ ]accepted[ ]from[ ].+because[ ]the[ ]ip[ ]is[ ]in[ ]Spamhaus's[ ]list
              )
            |Currently[ ]Sending[ ]Spam[ ]See:[ ]
            |domain[ ](?:
               .+[ ]mismatches[ ]client[ ]ip
              |does[ ]not[ ]exist:
              )
            |dns[ ]lookup[ ]failure:[ ].+[ ]try[ ]again[ ]later
            |DNSBL:ATTRBL
            |Dynamic/zombied/spam[ ]IPs[ ]blocked
            |Email[ ]blocked[ ]by[ ](?:.+[.]barracudacentral[.]org|SPAMHAUS)
            |Fix[ ]reverse[ ]DNS[ ]for[ ].+
            |Go[ ]away
            |host[ ].+[ ]refused[ ]to[ ]talk[ ]to[ ]me:[ ]\d+[ ]Blocked
            |hosts[ ]with[ ]dynamic[ ]ip
            |http://(?:
               spf[.]pobox[.]com/why[.]html
              |www[.]spamcop[.]net/bl[.]
              )
            |INVALID[ ]IP[ ]FOR[ ]SENDING[ ]MAIL[ ]OF[ ]DOMAIN
            |IP[ ]\d{1,3}[.]\d{1,3}[.]\d{1,3}[.]\d{1,3}[ ]is[ ]blocked[ ]by[ ]EarthLink # Earthlink
            |IP[/]domain[ ]reputation[ ]problems
            |is[ ](?:
               in[ ]a[ ]black[ ]list[ ]at[ ].+[.]
              |in[ ]an[ ].*RBL[ ]on[ ].+
              |not[ ]allowed[ ]to[ ]send[ ](?:
                 mail[ ]from
                |from[ ].+[ ]per[ ]it's[ ]SPF[ ]Record
                )
              )
            |mail[ ]server[ ]at[ ].+[ ]is[ ]blocked
            |Mail[ ]from[ ]\d+[.]\d+[.]\d+[.]\d[ ]refused:
            |Message[ ]from[ ].+[ ]rejected[ ]based[ ]on[ ]blacklist
            |Messages[ ]from[ ].+[ ]temporarily[ ]deferred[ ]due[ ]to[ ]user[ ]complaints   # Yahoo!
            |no[ ](?:
               access[ ]from[ ]mail[ ]server
              |PTR[ ]Record[ ]found[.]
              )
            |Not[ ]currently[ ]accepting[ ]mail[ ]from[ ]your[ ]ip  # Microsoft
            |part[ ]of[ ]their[ ]network[ ]is[ ]on[ ]our[ ]block[ ]list
            |Please[ ](?:
               get[ ]a[ ]custom[ ]reverse[ ]DNS[ ]name[ ]from[ ]your[ ]ISP[ ]for[ ]your[ ]host
              |inspect[ ]your[ ]SPF[ ]settings
              |use[ ]the[ ]smtp[ ]server[ ]of[ ]your[ ]ISP
              )
            |PTR[ ]record[ ]setup
            |Rejecting[ ]open[ ]proxy   # Sendmail(srvrsmtp.c)
            |Reverse[ ]DNS[ ](?:
               failed
              |required
              |lookup[ ]for[ ]host[ ].+[ ]failed[ ]permanently
              )
            |Sender[ ]IP[ ](?:
               address[ ]rejected
              |reverse[ ]lookup[ ]rejected
              )
            |Server[ ]access[ ](?:
               .+[ ]forbidden[ ]by[ ]invalid[ ]RDNS[ ]record[ ]of[ ]your[ ]mail[ ]server
              |forbidden[ ]by[ ]your[ ]IP[ ]
              )
            |Server[ ]IP[ ].+[ ]listed[ ]as[ ]abusive
            |service[ ]permits[ ]\d+[ ]unverifyable[ ]sending[ ]IPs
            |SMTP[ ]error[ ]from[ ]remote[ ]mail[ ]server[ ]after[ ]initial[ ]connection:   # Exim
            |sorry,[ ](?:
               that[ ]domain[ ]isn'?t[ ]in[ ]my[ ]list[ ]of[ ]allowed[ ]rcpthosts
              |your[ ]remotehost[ ]looks[ ]suspiciously[ ]like[ ]spammer
              )
            |SPF[ ](?:
               .+[ ]domain[ ]authentication[ ]fail
              |record
              |check:[ ]fail
              )
            |SPF:[ ].+[ ]is[ ]not[ ]allowed[ ]to[ ]send[ ]mail.+[A-Z]{3}.+401
            |the[ ](?:email|domain|ip).+[ ]is[ ]blacklisted
            |This[ ]system[ ]will[ ]not[ ]accept[ ]messages[ ]from[ ]servers[/]devices[ ]with[ ]no[ ]reverse[ ]DNS
            |Too[ ]many[ ]spams[ ]from[ ]your[ ]IP  # free.fr
            |unresolvable[ ]relay[ ]host[ ]name
            |Veuillez[ ]essayer[ ]plus[ ]tard.+[A-Z]{3}.+(?:103|510)
            |your[ ](?:
               network[ ]is[ ]temporary[ ]blacklisted
              |sender's[ ]IP[ ]address[ ]is[ ]listed[ ]at[ ].+[.]abuseat[.]org
              |server[ ]requires[ ]confirmation
              )
            |was[ ]blocked[ ]by[ ].+
            |we[ ]do[ ]not[ ]accept[ ]mail[ ]from[ ](?: # @mail.ru
               dynamic[ ]ips
              |hosts[ ]with[ ]dynamic[ ]IP[ ]or[ ]generic[ ]dns[ ]PTR-records
              )
            |You[ ]are[ ](?:
               not[ ]allowed[ ]to[ ]connect
              |sending[ ]spam
              )
            |Your[ ](?:
               access[ ]to[ ]submit[ ]messages[ ]to[ ]this[ ]e-mail[ ]system[ ]has[ ]been[ ]rejected
              |message[ ]was[ ]rejected[ ]for[ ]possible[ ]spam/virus[ ]content
              )
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
