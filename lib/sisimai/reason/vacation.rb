module Sisimai
  module Reason
    # Sisimai::Reason::Vacation is for only returning text and description.
    # This class is called only from Sisimai.reason method.
    module Vacation
      # Imported from p5-Sisimail/lib/Sisimai/Reason/Vacation.pm
      class << self
        def text; return 'vacation'; end
        def description
          return 'Email replied automatically due to a recipient is out of office'
        end
        def match;   return nil; end
        def true(*); return nil; end
      end
    end
  end
end

