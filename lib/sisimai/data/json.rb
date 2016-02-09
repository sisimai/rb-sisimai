module Sisimai
  class Data
    # Sisimai::Data::JSON dumps parsed data object as a JSON format. This class
    # and method should be called from the parent object "Sisimai::Data".
    module JSON
      # Imported from p5-Sisimail/lib/Sisimai/Data/JSON.pm
      class << self
        require 'oj'

        # Data dumper(JSON)
        # @param    [Sisimai::Data] argvs   Object
        # @return   [String, Nil]           Dumped data or Undef if the argument
        #                                   is missing
        def dump(argvs)
          return nil unless argvs
          return nil unless argvs.is_a? Sisimai::Data

          begin
            jsonstring = Oj.dump(argvs.damn, :mode => :compat)
          rescue
            warn '***warning: Failed to Oj.dump'
          end

          return jsonstring
        end

      end
    end
  end
end
