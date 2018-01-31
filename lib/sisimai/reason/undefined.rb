module Sisimai
  module Reason
    # Sisimai::Reason::Undefined is for only returning text and description.
    # This class is called only from Sisimai.reason method.
    module Undefined
      # Imported from p5-Sisimail/lib/Sisimai/Reason/Undefined.pm
      class << self
        def text; return 'undefined'; end
        def description; return 'Sisimai could not detect an error reason'; end
        def match;   return nil; end
        def true(*); return nil; end
      end
    end
  end
end

