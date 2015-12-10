module Sisimai
  module Reason
    # Sisimai::Reason::OnHold checks the bounce reason is "onhold" or not. This
    # class is called only Sisimai::Reason class.
    #
    # Sisimai will set C<onhold> to the reason of email bounce if there is no
    # (or less) detailed information about email bounce for judging the reason.
    module OnHold
      # Imported from p5-Sisimail/lib/Sisimai/Reason/OnHold.pm
      class << self
        def text; return 'onhold'; end
        def match; return false; end

        # On hold, Could not decide the bounce reason...
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: Status code is "onhold"
        #                                   false: is not "onhold"
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return nil unless argvs
          return nil unless argvs.is_a? Sisimai::Data
          return nil unless argvs.deliverystatus.size > 0
          return true if argvs.reason == self.text

          statuscode = argvs.deliverystatus || ''
          reasontext = self.text

          require 'sisimai/smtp/status'
          return true if Sisimai::SMTP::Status.name(statuscode) == reasontext
        end
      end
    end
  end
end



