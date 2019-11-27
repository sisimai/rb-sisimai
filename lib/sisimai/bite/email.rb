module Sisimai
  module Bite
    # Sisimai::Bite::Email- Base class for Sisimai::Bite::Email::*
    module Email
      class << self
        # Imported from p5-Sisimail/lib/Sisimai/Bite/Email.pm
        require 'sisimai/lhost'

        def INDICATORS; Sisimai::Lhost.warn; return Sisimai::Lhost.INDICATORS; end
        def headerlist; Sisimai::Lhost.warn; return Sisimai::Lhost.headerlist; end
        def index;      Sisimai::Lhost.warn; return Sisimai::Lhost.index; end
        def heads;      Sisimai::Lhost.warn; return Sisimai::Lhost.heads; end
        def scan;       Sisimai::Lhost.warn('make'); return Sisimai::Lhost.make; end
      end
    end
  end
end

