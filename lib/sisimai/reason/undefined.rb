module Sisimai
  module Reason
    # Sisimai::Reason::Undefined is for only returning text and description. This class is called only
    # from Sisimai.reason method.
    module Undefined
      class << self
        def text; return 'undefined'; end
        def description; return 'Sisimai could not detect an error reason'; end
        def match;   return false; end
        def true(*); return false; end
      end
    end
  end
end

