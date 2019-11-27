module Sisimai
  module Bite
    # Sisimai::Bite::JSON - Base class for Sisimai::Bite::JSON::*
    module JSON
      class << self
        # Imported from p5-Sisimail/lib/Sisimai/Bite/JSON.pm
        require 'sisimai/lhost'
        def INDICATORS; Sisimai::Lhost.warn('gone'); return Sisimai::Lhost.INDICATORS; end
        def index;      Sisimai::Lhost.warn('gone'); return Sisimai::Lhost.index; end
        def scan;       Sisimai::Lhost.warn('gone'); return Sisimai::Lhost.make; end
        def adapt;      Sisimai::Lhost.warn('gone'); return nil; end
      end
    end
  end
end

