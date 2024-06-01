module Sisimai
  # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Fact object as an argument
  # of get() method when the value of rhost of the object is listed in the results of Sisimai::Rhost
  # ->list method. This class is called only Sisimai::Fact class.
  module Rhost
    class << self
      RhostClass = {
        'Cox'       => ['cox.net'],
        'FrancePTT' => ['.laposte.net', '.orange.fr', '.wanadoo.fr'],
        'GoDaddy'   => ['smtp.secureserver.net', 'mailstore1.secureserver.net'],
        'Google'    => ['aspmx.l.google.com', 'gmail-smtp-in.l.google.com'],
        'IUA'       => ['.email.ua'],
        'KDDI'      => ['.ezweb.ne.jp', 'msmx.au.com'],
        'Microsoft' => ['.prod.outlook.com', '.protection.outlook.com'],
        'Mimecast'  => ['.mimecast.com'],
        'NTTDOCOMO' => ['mfsmax.docomo.ne.jp'],
        'Spectrum'  => ['charter.net'],
        'Tencent'   => ['.qq.com'],
      }.freeze

      # The value of "rhost" is listed in RhostClass or not
      # @param    [String] argvs  Remote host name
      # @return   [True,False]    True: matched
      #                           False: did not match
      def match(rhost)
        return false if rhost.empty?

        host0 = rhost.downcase
        match = false
        RhostClass.each_key do |e|
          # Try to match with each key of RhostClass
          next unless RhostClass[e].any? { |a| host0.end_with?(a) }
          match = true
          break
        end
        return match
      end

      # Detect the bounce reason from certain remote hosts
      # @param    [Hash]   argvs  Parsed email data
      # @param    [String] proxy  The alternative of the "rhost"
      # @return   [String]        The value of bounce reason
      def get(argvs, proxy = nil)
        remotehost = proxy || argvs['rhost'].downcase
        rhostclass = ''
        modulename = ''

        RhostClass.each_key do |e|
          # Try to match with each key of RhostClass
          next unless RhostClass[e].any? { |a| remotehost.end_with?(a) }
          modulename = 'Sisimai::Rhost::' << e
          rhostclass = 'sisimai/rhost/' << e.downcase
          break
        end
        return nil if rhostclass.empty?

        require rhostclass
        reasontext = Module.const_get(modulename).get(argvs)
        return reasontext
      end
    end
  end
end

