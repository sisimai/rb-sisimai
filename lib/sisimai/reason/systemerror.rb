module Sisimai
  module Reason
    # Sisimai::Reason::SystemError checks the bounce reason is "systemerror" or
    # not. This class is called only Sisimai::Reason class.
    #
    # This is the error that an email has bounced due to system error on the
    # remote host such as LDAP connection failure or other internal system error.
    #
    #   <kijitora@example.net>:
    #   Unable to contact LDAP server. (#4.4.3)I'm not going to try again; this
    #   message has been in the queue too long.
    module SystemError
      # Imported from p5-Sisimail/lib/Sisimai/Reason/SystemError.pm
      class << self
        def text; return 'systemerror'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          regex = %r{(?>
             can[']t[ ]create[ ]user[ ]output[ ]file
            |Internal[ ](?:
               error[ ]reading[ ]data                             # Microsoft
              |server[ ]error:[ ]Operation[ ]now[ ]in[ ]progress  # Microsoft
              )
            |interrupted[ ]system[ ]call
            |it[ ](?:
               encountered[ ]an[ ]error[ ]while[ ]being[ ]processed
              |would[ ]create[ ]a[ ]mail[ ]loop
              )
            |local[ ](?:
               configuration[ ]error
              |error[ ]in[ ]processing
              )
            |loop[ ]was[ ]found[ ]in[ ]the[ ]Mail[ ]eXchanger
            |mail[ ](?:
               for[ ].+[ ]loops[ ]back[ ]to[ ]myself
              |system[ ]configuration[ ]error
              )
            |server[ ]configuration[ ]error
            |service[ ]currently[ ]unavailable
            |system[ ]config[ ]error
            |timeout[ ]waiting[ ]for[ ]input
            )
          }ix

          return true if argv1 =~ regex
          return false
        end

        # The bounce reason is system error or not
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: is system error
        #                                   false: is not system error
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(_argvs)
          return nil
        end

      end
    end
  end
end



