module Sisimai
  class Data
    # Sisimai::Data::YAML dumps parsed data object as a YAML format. This class
    # and method should be called from the parent object "Sisimai::Data".
    module YAML
      # Imported from p5-Sisimail/lib/Sisimai/Data/YAML.pm
      class << self
        require 'yaml'

        # Data dumper(YAML)
        # @param    [Sisimai::Data] argvs Object
        # @return   [String, Nil]         Dumped data or nil if the argument
        #                                 is missing
        def dump(argvs)
          return nil unless argvs
          return nil unless argvs.is_a? Sisimai::Data

          damneddata = argvs.damn
          yamlstring = nil

          begin
            yamlstring = ::YAML.dump(damneddata)
          rescue StandardError => ce
            warn '***warning: Failed to YAML.dump: ' + ce.to_s
          end

          return yamlstring
        end

      end
    end
  end
end
