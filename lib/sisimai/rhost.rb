module Sisimai::Rhost
  # Imported from p5-Sisimail/lib/Sisimai/Rhost.pm
  class << self
    @@RhostClass = {
      'aspmx.l.google.com' => 'GoogleApps',
    }

    # Retrun the list of remote hosts Sisimai support
    # @return   [Array] Remote host list
    def list()
      return [ @@RhostClass.keys ]
    end

    # The value of "rhost" is listed in $RhostClass or not
    # @param    [String] argvs  Remote host name
    # @return   [True,False]    True: matched
    #                           False: did not match
    def match(argvs)
      return false unless argvs.is_a?(String)
      return true if @@RhostClass.has_key?(argvs.downcase)
      return false
    end

    # Detect the bounce reason from certain remote hosts
    # @param    [Sisimai::Data] argvs   Parsed email object
    # @return   [String]                The value of bounce reason
    def get(argvs)
      return nil unless argvs.is_a?(Sisimai::Data)
      return argvs.reason if argvs.reason

      reasontext = ''
      modulename = 'Sisimai::Rhost::' + @@RhostClass[argvs['rhost'].downcase]
      rhostclass = modulename.gsub('::', '/')
      rhostclass = rhostclass + @@RhostClass[argvs['rhost'].downcase]
      rhostcalss = rhostclass.downcase
      require rhostclass

      reasontext = modulename.get(argvs)
      return reasontext

    end
  end

end
