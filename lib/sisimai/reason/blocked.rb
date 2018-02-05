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
        def description; return 'Email rejected due to client IP address or a hostname'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          regex = %r{(?>
             access[ ]denied[.][ ]ip[ ]name[ ]lookup[ ]failed
            |access[ ]from[ ]ip[ ]address[ ].+[ ]blocked
            |all[ ]mail[ ]servers[ ]must[ ]have[ ]a[ ]ptr[ ]record[ ]with[ ]a[ ]valid[ ]reverse[ ]dns[ ]entry
            |bad[ ]sender[ ]ip[ ]address
            |blacklisted[ ]by
            |(?:blocked|refused)[ ]-[ ]see[ ]https?://
            |can[']t[ ]determine[ ]purported[ ]responsible[ ]address
            |cannot[ ](?:
               find[ ]your[ ]hostname
              |resolve[ ]your[ ]address
              )
            |client[ ]host[ ](?:
               .+[ ]blocked[ ]using
              |rejected:[ ](?:
                 abus[ ]detecte[ ]gu_eib_0[24]      # SFR
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
            |connections[ ](?:
               not[ ]accepted[ ]from[ ]ip[ ]addresses[ ]on[ ]spamhaus[ ]xbl
              |will[ ]not[ ]be[ ]accepted[ ]from[ ].+because[ ]the[ ]ip[ ]is[ ]in[ ]spamhaus's[ ]list
              )
            |currently[ ]sending[ ]spam[ ]see:[ ]
            |domain[ ](?:
               .+[ ]mismatches[ ]client[ ]ip
              |does[ ]not[ ]exist:
              )
            |dns[ ]lookup[ ]failure:[ ].+[ ]try[ ]again[ ]later
            |dnsbl:attrbl
            |dynamic/zombied/spam[ ]ips[ ]blocked
            |email[ ]blocked[ ]by[ ](?:.+[.]barracudacentral[.]org|spamhaus)
            |fix[ ]reverse[ ]dns[ ]for[ ].+
            |go[ ]away
            |host[ ].+[ ]refused[ ]to[ ]talk[ ]to[ ]me:[ ]\d+[ ]blocked
            |hosts[ ]with[ ]dynamic[ ]ip
            |http://(?:
               spf[.]pobox[.]com/why[.]html
              |www[.]spamcop[.]net/bl[.]
              )
            |invalid[ ]ip[ ]for[ ]sending[ ]mail[ ]of[ ]domain
            |ip[ ]\d{1,3}[.]\d{1,3}[.]\d{1,3}[.]\d{1,3}[ ]is[ ]blocked[ ]by[ ]EarthLink # Earthlink
            |ip[/]domain[ ]reputation[ ]problems
            |is[ ](?:
               in[ ]a[ ]black[ ]list[ ]at[ ].+[.]
              |in[ ]an[ ].*rbl[ ]on[ ].+
              |not[ ]allowed[ ]to[ ]send[ ](?:
                 mail[ ]from
                |from[ ].+[ ]per[ ]it's[ ]spf[ ]record
                )
              )
            |mail[ ]server[ ]at[ ].+[ ]is[ ]blocked
            |mail[ ]from[ ]\d+[.]\d+[.]\d+[.]\d[ ]refused:
            |message[ ]from[ ].+[ ]rejected[ ]based[ ]on[ ]blacklist
            |messages[ ]from[ ].+[ ]temporarily[ ]deferred[ ]due[ ]to[ ]user[ ]complaints   # Yahoo!
            |no[ ](?:
               access[ ]from[ ]mail[ ]server
              |ptr[ ]record[ ]found[.]
              )
            |not[ ]currently[ ]accepting[ ]mail[ ]from[ ]your[ ]ip  # Microsoft
            |part[ ]of[ ]their[ ]network[ ]is[ ]on[ ]our[ ]block[ ]list
            |please[ ](?:
               get[ ]a[ ]custom[ ]reverse[ ]dns[ ]name[ ]from[ ]your[ ]isp[ ]for[ ]your[ ]host
              |inspect[ ]your[ ]spf[ ]settings
              |use[ ]the[ ]smtp[ ]server[ ]of[ ]your[ ]isp
              )
            |ptr[ ]record[ ]setup
            |rejecting[ ]open[ ]proxy   # Sendmail(srvrsmtp.c)
            |reverse[ ]dns[ ](?:
               failed
              |required
              |lookup[ ]for[ ]host[ ].+[ ]failed[ ]permanently
              )
            |sender[ ]ip[ ](?:
               address[ ]rejected
              |reverse[ ]lookup[ ]rejected
              )
            |server[ ]access[ ](?:
               .+[ ]forbidden[ ]by[ ]invalid[ ]rdns[ ]record[ ]of[ ]your[ ]mail[ ]server
              |forbidden[ ]by[ ]your[ ]ip[ ]
              )
            |server[ ]ip[ ].+[ ]listed[ ]as[ ]abusive
            |service[ ]permits[ ]\d+[ ]unverifyable[ ]sending[ ]ips
            |smtp[ ]error[ ]from[ ]remote[ ]mail[ ]server[ ]after[ ]initial[ ]connection:   # Exim
            |sorry,[ ](?:
               that[ ]domain[ ]isn'?t[ ]in[ ]my[ ]list[ ]of[ ]allowed[ ]rcpthosts
              |your[ ]remotehost[ ]looks[ ]suspiciously[ ]like[ ]spammer
              )
            |spf[ ](?:
               .+[ ]domain[ ]authentication[ ]fail
              |record
              |check:[ ]fail
              )
            |spf:[ ].+[ ]is[ ]not[ ]allowed[ ]to[ ]send[ ]mail.+[a-z]{3}.+401
            |the[ ](?:email|domain|ip).+[ ]is[ ]blacklisted
            |this[ ]system[ ]will[ ]not[ ]accept[ ]messages[ ]from[ ]servers[/]devices[ ]with[ ]no[ ]reverse[ ]dns
            |too[ ]many[ ]spams[ ]from[ ]your[ ]ip  # free.fr
            |unresolvable[ ]relay[ ]host[ ]name
            |veuillez[ ]essayer[ ]plus[ ]tard.+[a-z]{3}.+(?:103|510)
            |your[ ](?:
               network[ ]is[ ]temporary[ ]blacklisted
              |sender's[ ]ip[ ]address[ ]is[ ]listed[ ]at[ ].+[.]abuseat[.]org
              |server[ ]requires[ ]confirmation
              )
            |was[ ]blocked[ ]by[ ].+
            |we[ ]do[ ]not[ ]accept[ ]mail[ ]from[ ](?: # @mail.ru
               dynamic[ ]ips
              |hosts[ ]with[ ]dynamic[ ]ip[ ]or[ ]generic[ ]dns[ ]ptr-records
              )
            |you[ ]are[ ](?:
               not[ ]allowed[ ]to[ ]connect
              |sending[ ]spam
              )
            |your[ ](?:
               access[ ]to[ ]submit[ ]messages[ ]to[ ]this[ ]e-mail[ ]system[ ]has[ ]been[ ]rejected
              |message[ ]was[ ]rejected[ ]for[ ]possible[ ]spam/virus[ ]content
              )
            )
          }x

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
          return true if argvs.reason == 'blocked'

          require 'sisimai/smtp/status'
          return true if Sisimai::SMTP::Status.name(argvs.deliverystatus) == 'blocked'
          return true if match(argvs.diagnosticcode.downcase)
          return false
        end

      end
    end
  end
end
