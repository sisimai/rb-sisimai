module Sisimai
  module Reason
    # Sisimai::Reason::Delivered checks the email you sent is delivered successfully or not by matching
    # diagnostic messages with message patterns. Sisimai will set "Delivered" to the value of "reason"
    # when Status: field in the bounce message begins with "2" like following:
    #
    #  Final-Recipient: rfc822; kijitora@neko.nyaan.jp
    #  Action: delivered
    #  Status: 2.1.5
    #  Diagnostic-Code: SMTP; 250 2.1.5 OK
    #
    # This class is called only Sisimai.reason method. This is NOT AN ERROR reason.
    module Delivered
      class << self
        require 'sisimai/eb'
        def text; return Sisimai::Eb::ReSENT; end
        def description; return 'Email delivered successfully'; end
        def match;   return false; end
        def true(*); return false; end
      end
    end
  end
end

