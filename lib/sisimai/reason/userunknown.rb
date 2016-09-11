module Sisimai
  module Reason
    # Sisimai::Reason::UserUnknown checks the bounce reason is "userunknown" or
    # not. This class is called only Sisimai::Reason class.
    #
    # This is the error that a local part (Left hand side of @ sign) of a recipient's
    # email address does not exist. In many case, a user has changed internet service
    # provider, or has quit company, or the local part is misspelled. Sisimai will
    # set "userunknown" to the reason of email bounce if the value of Status: field
    # in a bounce email is "5.1.1", or connection was refused at SMTP RCPT command,
    # or the contents of Diagnostic-Code: field represents that it is unknown user.
    #
    #   <kijitora@example.co.jp>: host mx01.example.co.jp[192.0.2.8] said:
    #   550 5.1.1 Address rejected kijitora@example.co.jp (in reply to
    #   RCPT TO command)
    module UserUnknown
      # Imported from p5-Sisimail/lib/Sisimai/Reason/UserUnknown.pm
      class << self
        def text; return 'userunknown'; end
        def description
          return "Email rejected due to a local part of a recipient's email address does not exist"
        end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          regex = %r{(?>
             .+[ ]user[ ]unknown
            |[#]5[.]1[.]1[ ]bad[ ]address
            |[<].+[>][ ]not[ ]found
            |address[ ]does[ ]not[ ]exist
            |address[ ]unknown
            |archived[ ]recipient
            |BAD[-_ ]RECIPIENT
            |destination[ ]addresses[ ]were[ ]unknown
            |destination[ ]server[ ]rejected[ ]recipients
            |email[ ]address[ ]does[ ]not[ ]exist
            |invalid[ ](?:
               address
              |mailbox[ ]path
              |recipient                 # Linkedin
              )
            |is[ ]not[ ](?:
               a[ ]known[ ]user
              |an[ ]active[ ]address[ ]at[ ]this[ ]host
              )
            |mailbox[ ](?:
               not[ ]present
              |not[ ]found
              |unavailable
              )
            |no[ ](?:
               account[ ]by[ ]that[ ]name[ ]here
              |mail[ ]box[ ]available[ ]for[ ]this[ ]user
              |mailbox[ ]found
              |matches[ ]to[ ]nameserver[ ]query
              |such[ ](?:
                 mailbox
                |person[ ]at[ ]this[ ]address
                |recipient
                |user(?:[ ]here)?
                )
              |[ ].+[ ]in[ ]name[ ]directory
              |valid[ ]recipients[,][ ]bye    # Microsoft
              )
            |non[- ]?existent[ ]user
            |not[ ](?:
               a[ ]valid[ ]user[ ]here
              |a[ ]local[ ]address
              )
            |rcpt[ ][<].+[>][ ]does[ ]not[ ]exist
            |recipient[ ](?:
               .+[ ]was[ ]not[ ]found[ ]in
              |address[ ]rejected:[ ](?:
                 access[ ]denied
                |invalid[ ]user
                |user[ ].+[ ]does[ ]not[ ]exist
                |user[ ]unknown[ ]in[ ].+[ ]table
                |unknown[ ]user
                )
              |does[ ]not[ ]exist(?:[ ]on[ ]this[ ]system)?
              |is[ ]not[ ]local
              |not[ ]found
              |not[ ]OK
              |unknown
              )
            |requested[ ]action[ ]not[ ]taken:[ ]mailbox[ ]unavailable
            |RESOLVER[.]ADR[.]RecipNotFound # Microsoft
            |said:[ ]550[-[ ]]5[.]1[.]1[ ].+[ ]user[ ]unknown[ ]
            |sorry,[ ](?:
               user[ ]unknown
              |badrcptto
              |no[ ]mailbox[ ]here[ ]by[ ]that[ ]name
              )
            |the[ ](?:
               following[ ]recipients[ ]was[ ]undeliverable
              |user[']s[ ]email[ ]name[ ]is[ ]not[ ]found
              )
            |this[ ](?:
               address[ ]no[ ]longer[ ]accepts[ ]mail
              |email[ ]address[ ]is[ ]wrong[ ]or[ ]no[ ]longer[ ]valid
              |user[ ]doesn[']?t[ ]have[ ]a[ ].+[ ]account
              )
            |unknown[ ](?:
               address
              |e[-]?mail[ ]address
              |local[- ]part
              |mailbox
              |recipient
              |user
              )
            |user[ ](?:
               .+[ ]was[ ]not[ ]found
              |.+[ ]does[ ]not[ ]exist
              |does[ ]not[ ]exist
              |missing[ ]home[ ]directory
              |not[ ]found     # 550 User not found. See http://mail.bigmir.net/err/2/
              |not[ ]known
              |unknown
              )
            |vdeliver:[ ]invalid[ ]or[ ]unknown[ ]virtual[ ]user
            )
          }ix

          return true if argv1 =~ regex
          return false
        end

        # Whether the address is "userunknown" or not
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: is unknown user
        #                                   false: is not unknown user.
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return nil unless argvs
          return nil unless argvs.is_a? Sisimai::Data
          return true if argvs.reason == Sisimai::Reason::UserUnknown.text

          require 'sisimai/smtp/status'
          prematches = %w|NoRelaying Blocked MailboxFull HasMoved|
          matchother = false
          statuscode = argvs.deliverystatus || ''
          diagnostic = argvs.diagnosticcode || ''
          reasontext = Sisimai::Reason::UserUnknown.text
          tempreason = Sisimai::SMTP::Status.name(statuscode)
          v = false

          return false if tempreason == 'suspend'

          if tempreason == reasontext
            # *.1.1 = 'Bad destination mailbox address'
            #   Status: 5.1.1
            #   Diagnostic-Code: SMTP; 550 5.1.1 <***@example.jp>:
            #     Recipient address rejected: User unknown in local recipient table
            prematches.each do |e|
              # Check the value of "Diagnostic-Code" with other error patterns.
              p = 'Sisimai::Reason::' + e
              r = nil
              begin
                require p.downcase.gsub('::', '/')
                r = Module.const_get(p)
              rescue
                warn '***warning: Failed to load ' + p
                next
              end

              if r.match(diagnostic)
                # Match with reason defined in Sisimai::Reason::* except UserUnknown.
                matchother = true
                break
              end
            end

            # Did not match with other message patterns
            v = true unless matchother

          else
            # Check the last SMTP command of the session.
            if argvs.smtpcommand == 'RCPT'
              # When the SMTP command is not "RCPT", the session rejected by other
              # reason, maybe.
              v = true if Sisimai::Reason::UserUnknown.match(diagnostic)
            end
          end

          return v
        end

      end
    end
  end
end



