module Sisimai
  module Reason
    # Sisimai::Reason::OnHold checks the bounce reason is "OnHold" or not. This class is called only
    # Sisimai::Reason class. Sisimai will set "OnHold" to the reason of email bounce if there is no
    # (or less) detailed information about email bounce for judging the reason.
    module OnHold
      class << self
        require 'sisimai/eb'
        def text; return Sisimai::Eb::Re___1; end
        def description; return 'Sisimai could not decided the reason due to there is no (or less) detailed information for judging the reason'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [Boolean]       false: Did not match, true: Matched
        def match(_argv1); return false; end

        # On hold, Could not decide the bounce reason...
        # @param    [Sisimai::Fact] argvs   Object to be detected the reason
        # @return   [Boolean]               true:  Status code is "OnHold"
        #                                   false: is not "OnHold"
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return false if argvs['deliverystatus'].empty?
          return true  if argvs['reason'] == Sisimai::Eb::Re___1
          return true  if Sisimai::SMTP::Status.name(argvs['deliverystatus']) == Sisimai::Eb::Re___1
          return false
        end
      end
    end
  end
end



