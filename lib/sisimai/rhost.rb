module Sisimai
  # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Data
  # object as an argument of get() method when the value of rhost of the object
  # is listed in the results of Sisimai::Rhost->list method.
  # This class is called only Sisimai::Data class.
  module Rhost
    # Imported from p5-Sisimail/lib/Sisimai/Rhost.pm
    class << self
      @@RhostClass = {
        'aspmx.l.google.com' => 'GoogleApps',
      }

      # Retrun the list of remote hosts Sisimai support
      # @return   [Array] Remote host list
      def list
        return @@RhostClass.keys
      end

      # The value of "rhost" is listed in $RhostClass or not
      # @param    [String] argvs  Remote host name
      # @return   [True,False]    True: matched
      #                           False: did not match
      def match(host)
        return false unless host.is_a?(::String)
        return true  if @@RhostClass.key?(host.downcase)
        return false
      end

      # Detect the bounce reason from certain remote hosts
      # @param    [Sisimai::Data] argvs   Parsed email object
      # @return   [String]                The value of bounce reason
      def get(data)
        return nil unless data.is_a?(Sisimai::Data)
        return data.reason if data.reason

        modulename  = 'Sisimai::Rhost::' + @@RhostClass[data['rhost'].downcase]
        rhostclass  = modulename.gsub('::', '/')
        rhostclass += @@RhostClass[data['rhost'].downcase]
        rhostclass  = rhostclass.downcase
        require rhostclass

        reasontext = modulename.get(data)
        return reasontext
      end
    end
  end
end
