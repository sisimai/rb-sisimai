module Sisimai
  module Reason
    # Sisimai::Reason::Feedback is for only returning text and description. This class is called only
    # from Sisimai.reason method and Sisimai::ARF class.
    module Feedback
      class << self
        def text; return 'feedback'; end
        def description; return 'Email forwarded to the sender as a complaint message from your mailbox provider'; end
        def match;   return false; end
        def true(*); return false; end
      end
    end
  end
end

