module Sisimai
  module Reason
    # Sisimai::Reason::Expired checks the bounce reason is "expired" or not.
    # This class is called only Sisimai::Reason class.
    #
    # This is the error that delivery time has expired due to connection failure
    # or network error and the message you sent has been in the queue for long
    # time.
    module Expired
      # Imported from p5-Sisimail/lib/Sisimai/Reason/Expired.pm
      class << self
        def text; return 'expired'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          regex = %r{(?:
             connection[ ]timed[ ]out
            |could[ ]not[ ]find[ ]a[ ]gateway[ ]for
            |delivery[ ]time[ ]expired
            |giving[ ]up[ ]on
            |it[ ]has[ ]not[ ]been[ ]collected[ ]after
            |message[ ]expired[ ]after[ ]sitting[ ]in[ ]queue[ ]for
            |Message[ ]timed[ ]out
            |retry[ ]time[ ]not[ ]reached[ ]for[ ]any[ ]host[ ]after[ ]a[ ]long[ ]failure[ ]period
            |server[ ]did[ ]not[ ]respond
            |this[ ]message[ ]has[ ]been[ ]in[ ]the[ ]queue[ ]too[ ]long
            |was[ ]not[ ]reachable[ ]within[ ]the[ ]allowed[ ]queue[ ]period
            )
          }ix

          return true if argv1 =~ regex
          return false
        end

        # Delivery expired due to connection failure or network error
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: is expired
        #                                   false: is not expired
        # @see      http://www.ietf.org/rfc/rfc2822.txt
        def true(_argvs)
          return nil
        end

      end
    end
  end
end


