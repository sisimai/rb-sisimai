module Sisimai
  module Reason
    module SpamDetected
      # Imported from p5-Sisimail/lib/Sisimai/Reason/SpamDetected.pm
      class << self
        def text; return 'spamdetected'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          regex = %r{(?>
             ["]The[ ]mail[ ]server[ ]detected[ ]your[ ]message[ ]as[ ]spam[ ]and[ ]
                has[ ]prevented[ ]delivery[.]["]    # CPanel/Exim with SA rejections on
            |(?:\d[.]\d[.]\d|\d{3})[ ]spam\z
            |appears[ ]to[ ]be[ ]unsolicited
            |Blacklisted[ ]URL[ ]in[ ]message
            |block[ ]for[ ]spam
            |blocked[ ]by[ ](?:
               policy:[ ]no[ ]spam[ ]please
              |spamAssassin                   # rejected by SpamAssassin
              )
            |blocked[ ]for[ ]abuse[.][ ]see[ ]http://att[.]net/blocks   # AT&T
            |bulk[ ]email
            |content[ ]filter[ ]rejection
            |cyberoam[ ]anti[ ]spam[ ]engine[ ]has[ ]identified[ ]this[ ]email[ ]as[ ]a[ ]bulk[ ]email
            |denied[ ]due[ ]to[ ]spam[ ]list
            |dt:spm[ ]mx.+[ ]http://mail[.]163[.]com/help/help_spam_16[.]htm
            |greylisted.?.[ ]please[ ]try[ ]again[ ]in
            |http://(?:
               www[.]spamhaus[.]org
              |dsbl[.]org
              |www[.]sorbs[.]net
              )
            |listed[ ]in[ ]work[.]drbl[.]imedia[.]ru
            |mail[ ](?:
               appears[ ]to[ ]be[ ]unsolicited    # rejected due to spam
              |content[ ]denied   # http://service.mail.qq.com/cgi-bin/help?subtype=1&&id=20022&&no=1000726
              )
            |may[ ]consider[ ]spam
            |message[ ](?:
               content[ ]rejected
              |filtered
              |filtered[.][ ]please[ ]see[ ]the[ ]faqs[ ]section[ ]on[ ]spam
              |filtered[.][ ]Refer[ ]to[ ]the[ ]Troubleshooting[ ]page[ ]at[ ]
              |looks[ ]like[ ]spam
              |not[ ]accepted[ ]for[ ]policy[ ]reasons[.][ ]See[ ]http:   # Yahoo!
              |refused[ ]by[ ]mailmarshal[ ]spamprofiler
              |rejected[ ]as[ ]spam
              |rejected[ ]as[ ]spam[ ]by[ ]Content[ ]Filtering
              |rejected[ ]due[ ]to[ ]suspected[ ]spam[ ]content
              |rejected[ ]for[ ]policy[ ]reasons
              )
            |our[ ]email[ ]server[ ]thinks[ ]this[ ]email[ ]is[ ]spam
            |our[ ]filters[ ]rate[ ]at[ ]and[ ]above[ ].+[ ]percent[ ]probability[ ]of[ ]being[ ]spam
            |our[ ]system[ ]has[ ]detected[ ]that[ ]this[ ]message[ ]is
            |probable[ ]spam
            |rejected(?:
               :[ ]spamassassin[ ]score[ ]
              |[ ]by[ ].+[ ][(]spam[)]
              |[ ]due[ ]to[ ]spam[ ]content
              )
            |rejecting[ ]banned[ ]content 
            |related[ ]to[ ]content[ ]with[ ]spam[-]like[ ]characteristics
            |rule[ ]imposed[ ]as[ ].+is[ ]blacklisted[ ]on              # Mailmarshal RBLs
            |sending[ ]address[ ]not[ ]accepted[ ]due[ ]to[ ]spam[ ]filter
            |spam[ ](?:
               blocked
              |check
              |content[ ]matched
              |detected
              |email
              |email[ ]not[ ]accepted
              |message[ ]rejected[.]       # mail.ru
              |not[ ]accepted
              |refused
              |rejection
              |Reporting[ ]Address    # SendGrid: a message to an address has previously been marked as Spam by the recipient.
              |score[ ]
              )
            |spambouncer[ ]identified[ ]spam    # SpamBouncer identified SPAM
            |spamming[ ]not[ ]allowed
            |Too[ ]much[ ]spam[.]               # Earthlink
            |the[ ]message[ ]was[ ]rejected[ ]due[ ]to[ ]classification[ ]as[ ]bulk[ ]mail
            |The[ ]content[ ]of[ ]this[ ]message[ ]looked[ ]like[ ]spam # SendGrid
            |this[ ]message[ ](?:
               appears[ ]to[ ]be[ ]spam
              |has[ ]been[ ]identified[ ]as[ ]spam
              |scored[ ].+[ ]spam[ ]points
              |was[ ]classified[ ]as[ ]spam
              )
            |transaction[ ]failed[ ]spam[ ]message[ ]not[ ]queued       # SendGrid
            |we[ ]dont[ ]accept[ ]spam
            |you're[ ]using[ ]a[ ]mass[ ]mailer
            |your[ ](?:
               email[ ](?:
                 appears[ ]similar[ ]to[ ]spam[ ]we[ ]have[ ]received[ ]before
                |breaches[ ]local[ ]URIBL[ ]policy
                |had[ ]spam[-]like[ ]
                |is[ ]considered[ ]spam
                |is[ ]probably[ ]spam
                |was[ ]detected[ ]as[ ]spam
                )
              |message[ ](?:
                 has[ ]been[ ](?:
                   temporarily[ ]blocked[ ]by[ ]our[ ]filter
                  |rejected[ ]because[ ]it[ ]appears[ ]to[ ]be[ ]SPAM
                  )
                |has[ ]triggered[ ]a[ ]SPAM[ ]block
                |may[ ]contain[ ]the[ ]spam[ ]contents
                |failed[ ]several[ ]antispam[ ]checks
                )
              )
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
          return true if argvs.reason == self.text

          require 'sisimai/smtp/status'
          require 'sisimai/reason/userunknown'
          statuscode = argvs.deliverystatus || ''
          commandtxt = argvs.smtpcommand || ''
          reasontext = self.text
          tempreason = ''
          diagnostic = ''
          v = false

          diagnostic = argvs.diagnosticcode || '';
          tempreason = Sisimai::SMTP::Status.name(statuscode)
          return false if tempreason == 'suspend'

          if tempreason == reasontext
            # Delivery status code points "filtered".
            if Sisimai::Reason::UserUnknown.match(diagnostic) || self.match(diagnostic)
                v = true
            end
          else
            # Check the value of Diagnostic-Code and the last SMTP command
            if commandtxt != 'RCPT' && commantxt != 'MAIL'
              # Check the last SMTP command of the session. 
              if self.match(diagnostic)
                # Matched with a pattern in this class
                v = true

              else
                # Did not match with patterns in this class,
                # Check the value of "Diagnostic-Code" with other error patterns.
                v = true if Sisimai::Reason::UserUnknown.match(diagnostic)
              end
            end
          end
          return v
        end

      end
    end
  end
end



