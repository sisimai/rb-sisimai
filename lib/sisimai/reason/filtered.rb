module Sisimai
  module Reason
    # Sisimai::Reason::Filtered checks the bounce reason is "filtered" or not.
    # This class is called only Sisimai::Reason class.
    #
    # This is the error that an email has been rejected by a header content after
    # SMTP DATA command.
    # In Japanese cellular phones, the error will incur that a sender's email address
    # or a domain is rejected by recipient's email configuration. Sisimai will
    # set "filtered" to the reason of email bounce if the value of Status: field
    # in a bounce email is "5.2.0" or "5.2.1".
    module Filtered
      # Imported from p5-Sisimail/lib/Sisimai/Reason/Filtered.pm
      class << self
        def text; return 'filtered'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          regex = %r{(?>
             because[ ]the[ ]recipient[ ]is[ ]only[ ]accepting[ ]mail[ ]from[ ]
              specific[ ]email[ ]addresses    # AOL Phoenix
            |Bounced[ ]Address  # SendGrid|a message to an address has previously been Bounced.
            |due[ ]to[ ]extended[ ]inactivity[ ]new[ ]mail[ ]is[ ]not[ ]currently[ ]
              being[ ]accepted[ ]for[ ]this[ ]mailbox
            |has[ ]restricted[ ]SMS[ ]e-mail    # AT&T
            |http://postmaster[.]facebook[.]com/.+refused[ ]due[ ]to[ ]recipient[ ]preferences # Facebook
            |permanent[ ]failure[ ]for[ ]one[ ]or[ ]more[ ]recipients[ ][(].+:blocked[)]
            |RESOLVER[.]RST[.]NotAuthorized # Microsoft Exchange
            |This[ ]account[ ]is[ ]protected[ ]by
            |user[ ](?:
              not[ ]found  # Filter on MAIL.RU
             |reject
             )
            |we[ ]failed[ ]to[ ]deliver[ ]mail[ ]because[ ]the[ ]following[ ]address
                [ ]recipient[ ]id[ ]refuse[ ]to[ ]receive[ ]mail    # Willcom
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
          return true if argvs.reason == Sisimai::Reason::Filtered.text

          require 'sisimai/smtp/status'
          require 'sisimai/reason/userunknown'
          commandtxt = argvs.smtpcommand || ''
          statuscode = argvs.deliverystatus || ''
          diagnostic = argvs.diagnosticcode || '';
          tempreason = Sisimai::SMTP::Status.name(statuscode)
          reasontext = Sisimai::Reason::Filtered.text
          v = false

          return false if tempreason == 'suspend'

          if tempreason == reasontext
            # Delivery status code points "filtered".
            if Sisimai::Reason::UserUnknown.match(diagnostic) ||
               Sisimai::Reason::Filtered.match(diagnostic)
                v = true
            end
          else
            # Check the value of Diagnostic-Code and the last SMTP command
            if commandtxt != 'RCPT' && commandtxt != 'MAIL'
              # Check the last SMTP command of the session.
              if Sisimai::Reason::Filtered.match(diagnostic)
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


