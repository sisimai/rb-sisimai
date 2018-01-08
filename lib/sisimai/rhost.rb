module Sisimai
  # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Data
  # object as an argument of get() method when the value of rhost of the object
  # is listed in the results of Sisimai::Rhost->list method.
  # This class is called only Sisimai::Data class.
  module Rhost
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Rhost.pm
      RhostClass = {
        %r/\Aaspmx[.]l[.]google[.]com\z/                 => 'GoogleApps',
        %r/[.](?:prod|protection)[.]outlook[.]com\z/     => 'ExchangeOnline',
        %r/\A(?:smtp|mailstore1)[.]secureserver[.]net\z/ => 'GoDaddy',
        %r/\b(?:laposte[.]net|orange[.]fr)\z/            => 'FrancePTT',
      }.freeze

      # Retrun the list of remote hosts Sisimai support
      # @return   [Array] Remote host list
      def list
        return RhostClass.keys
      end

      # The value of "rhost" is listed in RhostClass or not
      # @param    [String] argvs  Remote host name
      # @return   [True,False]    True: matched
      #                           False: did not match
      def match(rhost)
        return false unless rhost.is_a? ::String
        return false if rhost.empty?

        host0 = rhost.downcase
        match = false

        RhostClass.each_key do |e|
          # Try to match with each key of RhostClass
          next unless host0 =~ e
          match = true
          break
        end
        return match
      end

      # Detect the bounce reason from certain remote hosts
      # @param    [Sisimai::Data] argvs   Parsed email object
      # @return   [String]                The value of bounce reason
      def get(argvs)
        return nil unless argvs
        return nil unless argvs.is_a? Sisimai::Data
        return argvs.reason if argvs.reason.size > 0

        remotehost = argvs.rhost.downcase
        rhostclass = ''
        modulename = ''

        RhostClass.each_key do |e|
          # Try to match with each key of RhostClass
          next unless remotehost.end_with?(e)
          modulename = 'Sisimai::Rhost::' << RhostClass[e]
          rhostclass = modulename.gsub('::', '/').downcase
          break
        end

        require rhostclass
        reasontext = Module.const_get(modulename).get(argvs)
        return reasontext
      end
    end
  end
end
