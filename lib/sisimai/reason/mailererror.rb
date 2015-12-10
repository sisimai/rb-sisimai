module Sisimai
  module Reason
    # Sisimai::Reason::MailerError checks the bounce reason is C<mailererror> or not.
    # This class is called only Sisimai::Reason class.
    #
    # This is the error that a mailer program has not exited successfully or exited
    # unexpectedly on a destination mail server.
    #
    #   X-Actual-Recipient: X-Unix; |/home/kijitora/mail/catch.php
    #   Diagnostic-Code: X-Unix; 255
    module MailerError
      # Imported from p5-Sisimail/lib/Sisimai/Reason/MailerError.pm
      class << self
        def text; return 'mailererror'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          regex = %r{(?>
             command[ ](?:
               failed:[ ]
              |died[ ]with[ ]status[ ]\d+
              |output:
              )
            |\Aprocmail:[ ]    # procmail
            |bin/(?:procmail|maildrop)
            |mailer[ ]error
            |X[-]UNIX[;][ ]\d+  # X-UNIX; 127
            |exit[ ]\d+
            )
          }ix

          return true if argv1 =~ regex
          return false
        end

        def true; return nil; end

      end
    end
  end
end



