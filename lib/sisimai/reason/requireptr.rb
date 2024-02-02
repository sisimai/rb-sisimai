module Sisimai
  module Reason
    # Sisimai::Reason::RequirePTR checks the bounce reason is "requireptr" or not. This class is
    # called only from Sisimai::Reason class. This is the error that SMTP connection was rejected
    # due to missing PTR record or having invalid PTR record at the source IP address used for the
    # SMTP connection.
    module RequirePTR
      class << self
        require 'sisimai/string'

        Index = [
          'access denied. ip name lookup failed',
          'all mail servers must have a ptr record with a valid reverse dns entry',
          'bad dns ptr resource record',
          'cannot find your hostname',
          'client host rejected: cannot find your hostname',  # Yahoo!
          'fix reverse dns for ',
          'ips with missing ptr records',
          'no ptr record found.',
          'please get a custom reverse dns name from your isp for your host',
          'ptr record setup',
          'reverse dns failed',
          'reverse dns required',
          'sender ip reverse lookup rejected',
          'the ip address sending this message does not have a ptr record setup', # Google
          'the corresponding forward dns entry does not point to the sending ip', # Google
          'this system will not accept messages from servers/devices with no reverse dns',
          'unresolvable relay host name',
          'we do not accept mail from hosts with dynamic ip or generic dns ptr-records',
        ].freeze
        Pairs = [
          ['domain ',' mismatches client ip'],
          ['dns lookup failure: ', ' try again later'],
          ['reverse dns lookup for host ', ' failed permanently'],
          ['server access ', ' forbidden by invalid rdns record of your mail server'],
          ['service permits ', ' unverifyable sending ips'],
        ].freeze

        def text; return 'requireptr'; end
        def description; return 'Email rejected due to missing PTR record or having invalid PTR record'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          return true if Index.any? { |a| argv1.include?(a) }
          return true if Pairs.any? { |a| Sisimai::String.aligned(argv1, a) }
          return false
        end

        # Check the email rejected due to missing PTR record or having invalid PTR record OR not
        # @param    [Hash] argvs  Hash to be detected the value of reason
        # @return   [true,false]  true: is missing PTR or invalid PTR
        #                         false: is not blocked due to missing PTR record
        # @see      http://www.ietf.org/rfc/rfc5322.txt
        def true(argvs)
          return true if argvs['reason'] == 'requireptr'
          return true if Sisimai::SMTP::Status.name(argvs['deliverystatus']).to_s == 'requireptr'
          return true if match(argvs['diagnosticcode'].downcase)
          return false
        end

      end
    end
  end
end

